import React from 'react';
import ProductList from './ProductList.jsx';

const HomePage = () => {
  return (
    <div className="container mx-auto mt-8">
      <h2 className="text-3xl font-bold mb-4 text-sre-orange">Products</h2>
      <ProductList />
    </div>
  );
};

export default HomePage;
