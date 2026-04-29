import React from 'react';
import CartView from './CartView.jsx';

const CartPage = () => {
  return (
    <div className="container mx-auto mt-8">
      <h2 className="text-3xl font-bold mb-4 text-sre-orange">Shopping Cart</h2>
      <CartView />
    </div>
  );
};

export default CartPage;
