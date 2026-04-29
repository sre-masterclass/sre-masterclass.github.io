<template>
  <div id="app">
    <h1>Entropy Dashboard</h1>
    <div class="main-content">
      <div class="services-container">
        <ServiceCard
          v-for="service in services"
          :key="service.id"
          :service="service"
        />
        <ScenarioPanel />
      </div>
    </div>
  </div>
</template>

<script>
import ServiceCard from './components/ServiceCard.vue';
import ScenarioPanel from './components/ScenarioPanel.vue';
import api from './services/api';

export default {
  name: 'App',
  components: {
    ServiceCard,
    ScenarioPanel,
  },
  data() {
    return {
      services: [],
    };
  },
  methods: {
    async fetchServices() {
      try {
        const response = await api.getServices();
        this.services = response.data;
      } catch (error) {
        console.error('Failed to fetch services:', error);
      }
    },
  },
  created() {
    this.fetchServices();
  },
};
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  background-color: #1a2a45;
  color: #f5f1e8;
  padding: 20px;
  min-height: 100vh;
}

h1 {
  color: #f97316;
}

.main-content {
  display: flex;
  margin-top: 20px;
}
.services-container {
  display: flex;
  flex-wrap: wrap;
}
</style>
