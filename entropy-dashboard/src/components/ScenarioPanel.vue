<template>
  <div class="scenario-panel">
    <h3>Chaos Scenarios</h3>
    <ul>
      <li v-for="scenario in scenarios" :key="scenario.name">
        <span>
          {{ scenario.name }}
          <span class="tooltip" :title="scenario.description">?</span>
        </span>
        <span class="status" :class="getScenarioStatusClass(scenario.name)">
          {{ getScenarioStatus(scenario.name) }}
        </span>
        <button @click="runScenario(scenario.name)" :disabled="isScenarioRunning(scenario.name)">Run</button>
      </li>
    </ul>
    <button @click="resetEnvironment" class="reset-button">Reset Environment</button>
  </div>
</template>

<script>
import api from '../services/api';
import emitter from '../eventBus';

export default {
  name: 'ScenarioPanel',
  data() {
    return {
      scenarios: [],
      runningScenarios: [],
    };
  },
  methods: {
    getScenarioStatus(scenarioName) {
      return this.isScenarioRunning(scenarioName) ? 'Running' : 'Idle';
    },
    getScenarioStatusClass(scenarioName) {
      return this.isScenarioRunning(scenarioName) ? 'running' : 'idle';
    },
    isScenarioRunning(scenarioName) {
      return this.runningScenarios.includes(scenarioName);
    },
    async fetchScenarios() {
      try {
        const response = await api.getScenarios();
        console.log('Fetched scenarios:', response.data);
        this.scenarios = response.data;
      } catch (error) {
        console.error('Failed to fetch scenarios:', error);
      }
    },
    async runScenario(name) {
      try {
        await api.runScenario(name);
        alert(`Scenario "${name}" started.`);
      } catch (error) {
        console.error(`Failed to run scenario ${name}:`, error);
        alert(`Failed to start scenario "${name}".`);
      }
    },
    async fetchScenarioStatus() {
      try {
        const response = await api.getScenarioStatus();
        this.runningScenarios = response.data;
      } catch (error) {
        console.error('Failed to fetch scenario status:', error);
      }
    },
    async resetEnvironment() {
      try {
        await api.reset();
        emitter.emit('reset-toggles');
        emitter.emit('refresh-status');
        alert('Environment reset to normal.');
      } catch (error) {
        console.error('Failed to reset environment:', error);
        alert('Failed to reset environment.');
      }
    },
  },
  created() {
    this.fetchScenarios();
    this.fetchScenarioStatus();
    this.interval = setInterval(this.fetchScenarioStatus, 2000);
  },
  beforeUnmount() {
    clearInterval(this.interval);
  },
};
</script>

<style scoped>
.scenario-panel {
  background-color: #2c3e50;
  border: 1px solid #f97316;
  border-radius: 8px;
  padding: 16px;
  margin: 16px;
  flex-grow: 1;
  color: #f5f1e8;
}
h3 {
  color: #f97316;
}
ul {
  list-style: none;
  padding: 0;
}
li {
  display: grid;
  grid-template-columns: 1fr auto auto;
  gap: 10px;
  align-items: center;
  padding: 8px 0;
  border-bottom: 1px solid #f97316;
}
.status {
  font-style: italic;
  justify-self: center;
}
.running {
  color: #ff9800; /* A shade of orange */
}
.idle {
  color: #4caf50; /* A shade of green */
}
.tooltip {
  cursor: pointer;
  margin-left: 5px;
  border-bottom: 1px dotted #f5f1e8;
}
button {
  background-color: #f97316;
  color: #f5f1e8;
  border: none;
  border-radius: 4px;
  padding: 4px 8px;
  cursor: pointer;
}
button:hover {
  background-color: #fb923c;
}
.reset-button {
  margin-top: 10px;
  width: 100%;
  background-color: #f44336;
}
.reset-button:hover {
  background-color: #d32f2f;
}
</style>
