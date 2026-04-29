import React from 'react';
import { useLocation } from 'react-router-dom';
import OrderHistory from './OrderHistory.jsx';
import useWebSocket from '../hooks/useWebSocket';

const DashboardPage = () => {
  const location = useLocation();
  const params = new URLSearchParams(location.search);
  const orderId = params.get('orderId');
  const { messages } = useWebSocket(orderId ? `ws://localhost:8000/ws/orders/${orderId}` : null);

  return (
    <div className="container mx-auto mt-8">
      <h2 className="text-3xl font-bold mb-4 text-sre-orange">Dashboard</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        <div>
          <h3 className="text-2xl font-bold mb-4 text-sre-orange">Real-time Order Updates</h3>
          <ul className="text-sre-cream">
            {messages.map((msg, index) => (
              <li key={index}>{JSON.stringify(msg)}</li>
            ))}
          </ul>
        </div>
        <div>
          <OrderHistory />
        </div>
      </div>
    </div>
  );
};

export default DashboardPage;
