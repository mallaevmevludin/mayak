'use strict';
'use client';

import React, { useState, useEffect } from 'react';
import { supabase } from './supabase';

export default function Home() {
  const [session, setSession] = useState(null);
  const [authLoading, setAuthLoading] = useState(true);
  
  // Auth Inputs
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [authError, setAuthError] = useState(null);
  const [isSigningIn, setIsSigningIn] = useState(false);

  // Moderation State
  const [jobs, setJobs] = useState([]);
  const [loadingJobs, setLoadingJobs] = useState(false);
  const [filter, setFilter] = useState('pending'); // pending, active, rejected, all
  
  // Rejection Dialog State
  const [rejectingJobId, setRejectingJobId] = useState(null);
  const [rejectionComment, setRejectionComment] = useState('');
  const [isRejecting, setIsRejecting] = useState(false);

  // Check current session on mount
  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setAuthLoading(false);
      if (session) {
        fetchJobs();
      }
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      if (session) {
        fetchJobs();
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  // Fetch jobs from Supabase
  const fetchJobs = async () => {
    setLoadingJobs(true);
    try {
      const { data, error } = await supabase
        .from('jobs')
        .select(`
          id, title, description, category, budget, status, created_at, user_id,
          contact_phone, contact_telegram, image_urls, rejection_comment,
          profiles!jobs_user_id_profiles_fkey(first_name, last_name, username, emoji_avatar, avatar_url, is_verified)
        `)
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Supabase error details:', error.message, error.code, error.hint);
        throw error;
      }
      setJobs(data || []);
    } catch (err) {
      console.error('Error fetching jobs:', err);
    } finally {
      setLoadingJobs(false);
    }
  };

  // Sign In handler
  const handleSignIn = async (e) => {
    e.preventDefault();
    if (!email || !password) return;
    setIsSigningIn(true);
    setAuthError(null);

    try {
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
    } catch (err) {
      setAuthError(err.message);
    } finally {
      setIsSigningIn(false);
    }
  };

  // Sign Out handler
  const handleSignOut = async () => {
    await supabase.auth.signOut();
    setSession(null);
    setJobs([]);
  };

  // Approve a job listing
  const handleApprove = async (jobId) => {
    try {
      const { error } = await supabase
        .from('jobs')
        .update({ status: 'active', rejection_comment: null })
        .eq('id', jobId);

      if (error) throw error;
      fetchJobs();
    } catch (err) {
      alert('Ошибка при одобрении: ' + err.message);
    }
  };

  // Open rejection modal
  const openRejectionDialog = (jobId) => {
    setRejectingJobId(jobId);
    setRejectionComment('');
  };

  // Submit rejection
  const handleRejectSubmit = async (e) => {
    e.preventDefault();
    if (!rejectingJobId) return;
    setIsRejecting(true);

    try {
      const { error } = await supabase
        .from('jobs')
        .update({
          status: 'rejected',
          rejection_comment: rejectionComment.trim() || 'Нарушение правил публикации.'
        })
        .eq('id', rejectingJobId);

      if (error) throw error;
      setRejectingJobId(null);
      fetchJobs();
    } catch (err) {
      alert('Ошибка при отклонении: ' + err.message);
    } finally {
      setIsRejecting(false);
    }
  };

  // Filter jobs list
  const filteredJobs = jobs.filter((job) => {
    if (filter === 'all') return true;
    return job.status === filter;
  });

  // Calculate statistics
  const stats = {
    pending: jobs.filter(j => j.status === 'pending').length,
    active: jobs.filter(j => j.status === 'active').length,
    rejected: jobs.filter(j => j.status === 'rejected').length,
  };

  // Display loading screen while verifying session
  if (authLoading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
      </div>
    );
  }

  // Display Login Page if not authenticated
  if (!session) {
    return (
      <div className="login-page">
        <div className="login-card">
          <div className="logo-section">
            <span className="logo-emoji">🚨</span>
            <h1>Панель модератора</h1>
            <p>Войдите, чтобы проверять новые заказы</p>
          </div>
          
          <form onSubmit={handleSignIn} className="login-form">
            {authError && <div className="error-alert">{authError}</div>}
            
            <div className="input-group">
              <label>Эл. почта</label>
              <input
                type="email"
                required
                placeholder="admin@example.com"
                value={email}
                onChange={e => setEmail(e.target.value)}
              />
            </div>
            
            <div className="input-group">
              <label>Пароль</label>
              <input
                type="password"
                required
                placeholder="••••••••"
                value={password}
                onChange={e => setPassword(e.target.value)}
              />
            </div>

            <button type="submit" disabled={isSigningIn} className="submit-btn">
              {isSigningIn ? 'Вход...' : 'Войти'}
            </button>
          </form>
        </div>
      </div>
    );
  }

  // Display Dashboard if authenticated
  return (
    <div className="dashboard-layout">
      {/* Sidebar Navigation */}
      <aside className="sidebar">
        <div className="sidebar-brand">
          <span className="brand-emoji">🚨</span>
          <h2>Маяк Модерация</h2>
        </div>
        
        <div className="user-profile">
          <div className="avatar">🔑</div>
          <div className="user-details">
            <span className="user-email" title={session.user.email}>
              {session.user.email}
            </span>
            <span className="user-role">Модератор</span>
          </div>
        </div>

        <nav className="nav-menu">
          <button 
            className={`nav-item ${filter === 'pending' ? 'active' : ''}`}
            onClick={() => setFilter('pending')}
          >
            <span>📥 На проверке</span>
            <span className="badge pending">{stats.pending}</span>
          </button>
          
          <button 
            className={`nav-item ${filter === 'active' ? 'active' : ''}`}
            onClick={() => setFilter('active')}
          >
            <span>✅ Опубликовано</span>
            <span className="badge active">{stats.active}</span>
          </button>

          <button 
            className={`nav-item ${filter === 'rejected' ? 'active' : ''}`}
            onClick={() => setFilter('rejected')}
          >
            <span>❌ Отклонено</span>
            <span className="badge rejected">{stats.rejected}</span>
          </button>

          <button 
            className={`nav-item ${filter === 'all' ? 'active' : ''}`}
            onClick={() => setFilter('all')}
          >
            <span>🌐 Все заказы</span>
            <span className="badge all">{jobs.length}</span>
          </button>
        </nav>

        <button onClick={handleSignOut} className="logout-btn">
          🚪 Выйти
        </button>
      </aside>

      {/* Main Content Area */}
      <main className="main-content">
        <header className="topbar">
          <div className="page-info">
            <h1>Moderation Queue</h1>
            <p>Проверка и управление объявлениями на фриланс-витрине</p>
          </div>
          <button onClick={fetchJobs} className="refresh-btn">
            🔄 Обновить список
          </button>
        </header>

        {loadingJobs ? (
          <div className="content-loading">
            <div className="spinner"></div>
            <p>Загрузка объявлений...</p>
          </div>
        ) : filteredJobs.length === 0 ? (
          <div className="empty-state">
            <span className="empty-emoji">🎉</span>
            <h3>Нет заказов в этой категории</h3>
            <p>Все чисто! Отличная работа.</p>
          </div>
        ) : (
          <div className="jobs-grid">
            {filteredJobs.map((job) => {
              const profile = job.profiles || {};
              const formattedDate = new Date(job.created_at).toLocaleDateString('ru-RU', {
                day: 'numeric',
                month: 'long',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
              });

              return (
                <div key={job.id} className={`job-card status-${job.status}`}>
                  <div className="card-header">
                    <span className="category-tag">
                      {job.category}
                    </span>
                    <span className={`status-badge ${job.status}`}>
                      {job.status === 'pending' && 'На проверке'}
                      {job.status === 'active' && 'Опубликован'}
                      {job.status === 'rejected' && 'Отклонен'}
                      {job.status === 'closed' && 'Закрыт'}
                    </span>
                  </div>

                  <div className="card-body">
                    <h2 className="job-title">{job.title}</h2>
                    <p className="job-description">{job.description}</p>

                    {/* Image Previews */}
                    {job.image_urls && job.image_urls.length > 0 && (
                      <div className="images-preview-row">
                        {job.image_urls.map((url, i) => (
                          <a href={url} target="_blank" rel="noopener noreferrer" key={i}>
                            <img src={url} alt={`Preview ${i}`} className="preview-thumbnail" />
                          </a>
                        ))}
                      </div>
                    )}

                    <div className="meta-details">
                      <div className="meta-item">
                        <span className="meta-label">💰 Бюджет:</span>
                        <span className="meta-value budget">{job.budget || 'Договорная'}</span>
                      </div>
                      <div className="meta-item">
                        <span className="meta-label">👤 Заказчик:</span>
                        <span className="meta-value">
                          {profile.emoji_avatar || '👤'} {profile.first_name} {profile.last_name} (@{profile.username})
                        </span>
                      </div>
                      <div className="meta-item">
                        <span className="meta-label">📞 Телефон:</span>
                        <span className="meta-value">{job.contact_phone || 'Не указан'}</span>
                      </div>
                      {job.contact_telegram && (
                        <div className="meta-item">
                          <span className="meta-label">✈️ Telegram:</span>
                          <span className="meta-value">{job.contact_telegram}</span>
                        </div>
                      )}
                      <div className="meta-item">
                        <span className="meta-label">📅 Создан:</span>
                        <span className="meta-value">{formattedDate}</span>
                      </div>
                    </div>

                    {job.status === 'rejected' && job.rejection_comment && (
                      <div className="rejection-reason-box">
                        <strong>Причина отказа:</strong> {job.rejection_comment}
                      </div>
                    )}
                  </div>

                  <div className="card-actions">
                    {job.status === 'pending' && (
                      <>
                        <button 
                          onClick={() => handleApprove(job.id)}
                          className="action-btn approve"
                        >
                          Одобрить
                        </button>
                        <button 
                          onClick={() => openRejectionDialog(job.id)}
                          className="action-btn reject"
                        >
                          Отклонить
                        </button>
                      </>
                    )}
                    {job.status === 'active' && (
                      <button 
                        onClick={() => openRejectionDialog(job.id)}
                        className="action-btn reject outline"
                      >
                        Снять с публикации / Отклонить
                      </button>
                    )}
                    {job.status === 'rejected' && (
                      <button 
                        onClick={() => handleApprove(job.id)}
                        className="action-btn approve outline"
                      >
                        Перепроверить и Одобрить
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </main>

      {/* Rejection Dialog Modal */}
      {rejectingJobId && (
        <div className="modal-overlay">
          <div className="modal-card">
            <h3>Укажите причину отклонения</h3>
            <p>Исполнитель увидит этот комментарий и сможет отредактировать объявление.</p>
            
            <form onSubmit={handleRejectSubmit}>
              <textarea
                required
                rows="4"
                placeholder="Например: Некорректный бюджет или спам в описании..."
                value={rejectionComment}
                onChange={e => setRejectionComment(e.target.value)}
              ></textarea>
              
              <div className="modal-actions">
                <button 
                  type="button" 
                  onClick={() => setRejectingJobId(null)}
                  className="modal-btn cancel"
                >
                  Отмена
                </button>
                <button 
                  type="submit" 
                  disabled={isRejecting} 
                  className="modal-btn submit"
                >
                  {isRejecting ? 'Отправка...' : 'Отклонить объявление'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
