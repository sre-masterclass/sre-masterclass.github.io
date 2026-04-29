import React from 'react';
import CheckoutForm from './CheckoutForm.jsx';

const CheckoutPage = () => {
  return (
    <div className="container mx-auto mt-8">
      <h2 className="text-3xl font-bold mb-4 text-sre-orange">Checkout</h2>
      <CheckoutForm />
    </div>
  );
};

export default CheckoutPage;
