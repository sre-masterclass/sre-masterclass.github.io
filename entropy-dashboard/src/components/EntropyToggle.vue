<template>
  <div class="entropy-toggle">
    <label>{{ type }}</label>
    <select v-model="level" @change="updateEntropy">
      <option value="0">Normal</option>
      <option value="0.25">Degraded</option>
      <option value="0.5">Critical</option>
    </select>
  </div>
</template>

<script>
import api from '../services/api';
import emitter from '../eventBus';

export default {
  name: 'EntropyToggle',
  props: {
    serviceId: {
      type: String,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      level: '0',
    };
  },
  methods: {
    async updateEntropy() {
      try {
        await api.setEntropy(this.serviceId, this.type, parseFloat(this.level));
        this.$emit('status-updated');
      } catch (error) {
        console.error(`Failed to set ${this.type}:`, error);
        // Optionally, revert the select box to the previous value
      }
    },
    resetLevel() {
      this.level = '0';
    },
  },
  async created() {
    emitter.on('reset-toggles', this.resetLevel);
    try {
      const response = await api.getServiceStatus(this.serviceId);
      const state = response.data;
      this.level = state[this.type] || '0';
    } catch (error) {
      console.error(`Failed to fetch initial state for ${this.serviceId}:`, error);
    }
  },
  beforeUnmount() {
    emitter.off('reset-toggles', this.resetLevel);
  },
};
</script>

<style scoped>
.entropy-toggle {
  display: flex;
  flex-direction: column;
}
label {
  text-transform: capitalize;
  margin-bottom: 4px;
  color: #f5f1e8;
}
select {
  background-color: #2c3e50;
  color: #f5f1e8;
  border: 1px solid #f97316;
  border-radius: 4px;
  padding: 4px 8px;
}
</style>
