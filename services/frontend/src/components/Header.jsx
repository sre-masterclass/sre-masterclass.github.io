import React from 'react';
import { Link } from 'react-router-dom';

const Header = () => {
  return (
    <header className="bg-sre-dark-blue text-sre-cream p-4">
      <div className="container mx-auto flex justify-between items-center">
        <h1 className="text-2xl font-bold">
          <Link to="/">SRE Masterclass</Link>
        </h1>
        <nav>
          <ul className="flex space-x-4">
            <li><Link to="/" className="hover:text-sre-orange">Home</Link></li>
            <li><Link to="/cart" className="hover:text-sre-orange">Cart</Link></li>
            <li><Link to="/dashboard" className="hover:text-sre-orange">Dashboard</Link></li>
            <li><Link to="/login" className="hover:text-sre-orange">Login</Link></li>
          </ul>
        </nav>
      </div>
    </header>
  );
};

export default Header;
