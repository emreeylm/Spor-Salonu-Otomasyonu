document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    const errorDiv = document.getElementById('loginError');
    const btn = document.querySelector('.login-btn');

    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> BEKLENİYOR...';
    btn.disabled = true;
    errorDiv.style.display = 'none';

    try {
        const res = await fetch('/api/auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password })
        });

        const data = await res.json();

        if (res.ok) {
            // Save token and info
            localStorage.setItem('token', data.token);
            localStorage.setItem('username', data.username);
            localStorage.setItem('role', data.role);
            
            // Redirect to dashboard
            window.location.href = 'index.html';
        } else {
            errorDiv.textContent = data.error || 'Giriş yapılamadı.';
            errorDiv.style.display = 'block';
            btn.innerHTML = 'GİRİŞ YAP <i class="fas fa-arrow-right"></i>';
            btn.disabled = false;
        }
    } catch (err) {
        errorDiv.textContent = 'Sunucuya bağlanılamadı.';
        errorDiv.style.display = 'block';
        btn.innerHTML = 'GİRİŞ YAP <i class="fas fa-arrow-right"></i>';
        btn.disabled = false;
    }
});
