import React, { useState } from 'react';

const LoginForm = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');

  const handleLogin = async (e) => {
    e.preventDefault();
    try {
      const response = await fetch('/api/auth/token', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          username,
          password,
        }),
      });
      if (response.ok) {
        window.location.href = '/dashboard';
      } else {
        console.error('Login failed');
      }
    } catch (error) {
      console.error('Error logging in:', error);
    }
  };

  return (
    <form className="w-full max-w-sm" onSubmit={handleLogin}>
      <div className="md:flex md:items-center mb-6">
        <div className="md:w-1/3">
          <label className="block text-sre-cream font-bold md:text-right mb-1 md:mb-0 pr-4" htmlFor="inline-full-name">
            Username
          </label>
        </div>
        <div className="md:w-2/3">
          <input
            className="bg-sre-dark-blue appearance-none border-2 border-sre-orange rounded w-full py-2 px-4 text-sre-cream leading-tight focus:outline-none focus:bg-sre-cream focus:text-sre-dark-blue"
            id="inline-full-name"
            type="text"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
          />
        </div>
      </div>
      <div className="md:flex md:items-center mb-6">
        <div className="md:w-1/3">
          <label className="block text-sre-cream font-bold md:text-right mb-1 md:mb-0 pr-4" htmlFor="inline-password">
            Password
          </label>
        </div>
        <div className="md:w-2/3">
          <input
            className="bg-sre-dark-blue appearance-none border-2 border-sre-orange rounded w-full py-2 px-4 text-sre-cream leading-tight focus:outline-none focus:bg-sre-cream focus:text-sre-dark-blue"
            id="inline-password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </div>
      </div>
      <div className="md:flex md:items-center">
        <div className="md:w-1/3"></div>
        <div className="md:w-2/3">
          <button className="shadow bg-sre-orange hover:bg-orange-600 focus:shadow-outline focus:outline-none text-sre-cream font-bold py-2 px-4 rounded" type="submit">
            Login
          </button>
        </div>
      </div>
    </form>
  );
};

export default LoginForm;
