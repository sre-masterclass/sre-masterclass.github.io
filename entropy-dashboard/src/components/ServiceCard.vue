<template>
  <div class="service-card">
    <h3>{{ service.name }}</h3>
    <p>Status: <span :class="statusClass">{{ status }}</span></p>
    <div class="controls">
      <EntropyToggle :service-id="service.id" type="latency" @status-updated="fetchStatus" />
      <EntropyToggle :service-id="service.id" type="errors" @status-updated="fetchStatus" />
    </div>
  </div>
</template>

<script>
import EntropyToggle from './EntropyToggle.vue';
import api from '../services/api';
import emitter from '../eventBus';

export default {
  name: 'ServiceCard',
  components: {
    EntropyToggle,
  },
  props: {
    service: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      status: 'loading...',
      statusClass: 'loading',
      latency: 0,
      error_rate: 0,
    };
  },
  methods: {
    async fetchStatus() {
      try {
        const response = await api.getServiceStatus(this.service.id);
        const state = response.data;
        this.latency = state.latency || 0;
        this.error_rate = state.error_rate || 0;
        this.updateStatus();
      } catch (error) {
        this.status = 'error';
        this.statusClass = 'critical';
      }
    },
    updateStatus() {
      if (this.latency >= 0.5 || this.error_rate >= 0.5) {
        this.status = 'critical';
        this.statusClass = 'critical';
      } else if (this.latency > 0 || this.error_rate > 0) {
        this.status = 'degraded';
        this.statusClass = 'degraded';
      } else {
        this.status = 'ok';
        this.statusClass = 'ok';
      }
    },
  },
  created() {
    this.fetchStatus();
    this.interval = setInterval(this.fetchStatus, 2000);
    emitter.on('refresh-status', this.fetchStatus);
  },
  beforeUnmount() {
    clearInterval(this.interval);
    emitter.off('refresh-status', this.fetchStatus);
  },
};
</script>

<style scoped>
.service-card {
  background-color: #2c3e50;
  border: 1px solid #f97316;
  border-radius: 8px;
  padding: 16px;
  margin: 16px;
  width: 300px;
  color: #f5f1e8;
}
h3 {
  color: #f97316;
}
.controls {
  display: flex;
  justify-content: space-around;
  margin-top: 16px;
}
.ok {
  color: #4caf50; /* A shade of green */
}
.degraded {
  color: #ff9800; /* A shade of orange */
}
.critical {
  color: #f44336; /* A shade of red */
}
.loading {
  color: #9e9e9e; /* A shade of grey */
}
</style>
