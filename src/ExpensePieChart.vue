<script>
import { PieChart } from "vue-chart-3";
import { computed } from "vue";

const COLORS = [
  "#3b82f6",
  "#22c55e",
  "#eab308",
  "#ef4444",
  "#8b5cf6",
  "#ec4899",
  "#06b6d4",
  "#f97316",
];

export default {
  name: "ExpensePieChart",
  components: { PieChart },
  props: {
    expenses: {
      type: Array,
      default: () => [],
    },
    textColor: {
      type: String,
      default: "#111827",
    },
  },
  setup(props) {
    const chartData = computed(() => {
      const byCategory = {};
      for (const e of props.expenses) {
        const cat = e.category || "Other";
        byCategory[cat] = (byCategory[cat] || 0) + Number(e.amount);
      }
      const labels = Object.keys(byCategory);
      const data = labels.map((l) => byCategory[l]);
      const backgroundColor = labels.map((_, i) => COLORS[i % COLORS.length]);
      return {
        labels,
        datasets: [
          {
            data,
            backgroundColor,
            borderWidth: 1,
            borderColor: "#fff",
          },
        ],
      };
    });
    const chartOptions = computed(() => ({
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: "bottom",
          labels: {
            color: props.textColor,
          },
        },
        tooltip: {
          titleColor: "white",
          bodyColor: "white",
          callbacks: {
            label(context) {
              const total = context.dataset.data.reduce((a, b) => a + b, 0);
              const value = context.raw;
              const pct = total ? ((value / total) * 100).toFixed(1) : 0;
              return ` ${context.label}: $${value.toFixed(2)} (${pct}%)`;
            },
          },
        },
      },
    }));
    const hasData = computed(() => {
      const d = chartData.value;
      return d.datasets?.[0]?.data?.length > 0;
    });
    return { chartData, chartOptions, hasData };
  },
};
</script>

<template>
  <div
    v-if="hasData"
    class="w-full border border-black rounded overflow-hidden"
    :style="{ backgroundColor: 'var(--theme-surface)' }"
  >
    <div
      class="p-2 border-b border-black text-sm font-medium"
      :style="{ color: textColor }"
    >
      Spending by category
    </div>
    <div class="p-4" style="height: 280px">
      <PieChart
        :chartData="chartData"
        :options="chartOptions"
        :height="260"
        :width="260"
      />
    </div>
  </div>
  <p v-else class="text-sm py-2 opacity-80" :style="{ color: textColor }">
    Add expenses to see the chart.
  </p>
</template>
