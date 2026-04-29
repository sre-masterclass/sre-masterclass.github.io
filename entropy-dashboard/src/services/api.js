import axios from 'axios';

const apiClient = axios.create({
  baseURL: '/api', // Using a proxy to avoid CORS issues
  headers: {
    'Content-Type': 'application/json',
  },
});

export default {
  getServices() {
    return apiClient.get('/services');
  },
  getServiceStatus(serviceId) {
    return apiClient.get(`/entropy/status/${serviceId}`);
  },
  setEntropy(serviceId, type, level) {
    const state = {};
    state[type] = parseFloat(level);
    return apiClient.post('/entropy/set', {
      service_id: serviceId,
      state,
    });
  },
  runScenario(name) {
    return apiClient.post('/scenarios/run', { name });
  },
  getScenarios() {
    return apiClient.get('/scenarios');
  },
  getScenarioStatus() {
    return apiClient.get('/scenarios/status');
  },
  reset() {
    return apiClient.post('/entropy/reset');
  },
};
