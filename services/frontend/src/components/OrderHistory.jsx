import React, { useEffect, useState } from 'react';
import useWebSocket from '../hooks/useWebSocket';

const OrderHistory = () => {
  const [orders, setOrders] = useState([]);
  const { messages } = useWebSocket('ws://localhost:8000/ws/orders');

  useEffect(() => {
    const fetchOrders = async () => {
      try {
        const response = await fetch('/api/orders');
        const data = await response.json();
        if (Array.isArray(data)) {
          setOrders(data);
        }
      } catch (error) {
        console.error('Error fetching orders:', error);
      }
    };

    fetchOrders();
  }, []);

  useEffect(() => {
    if (messages.length > 0) {
      const newOrder = messages[messages.length - 1];
      setOrders((prevOrders) =>
        prevOrders.map((order) =>
          order.id === newOrder.order_id ? { ...order, status: newOrder.status } : order
        )
      );
    }
  }, [messages]);

  return (
    <div>
      <h2 className="text-2xl font-bold mb-4 text-sre-orange">Order History</h2>
      {orders.map((order) => (
        <div key={order.id} className="border-b border-sre-orange py-4 text-sre-cream">
          <p><span className="font-bold">Order ID:</span> {order.id}</p>
          <p><span className="font-bold">Status:</span> {order.status}</p>
          <p><span className="font-bold">Created At:</span> {order.created_at}</p>
        </div>
      ))}
    </div>
  );
};

export default OrderHistory;
