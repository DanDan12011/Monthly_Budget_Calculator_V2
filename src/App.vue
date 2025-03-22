<script>
export default {
  data() {
    return {
      money: null,
      months: null,
      month_budg: 0,
      rows: [{ category: "", percentage: "" }],
    };
  },
  computed: {
    month_budg() {
      if (this.money > 0 && this.months > 0) {
        return (
          Math.round((this.month_budg = this.money / this.months) * 100) / 100
        );
      } else {
        return (this.month_budg = 0);
      }
    },
  },
  methods: {
    addrow() {
      this.rows.push({ category: "", percentage: "" });
    },
    deleterow(index) {
      if (this.rows.length > 1) {
        this.rows.splice(index, 1);
      }
    },
    resetrows() {
      this.rows = [{ category: "", percentage: "" }];
    },
  },
};
</script>

<template>
  <div class="flex flex-col items-center justify-center">
    <h1 class="text-lg font-bold">Monthly Budget Calculator</h1>
    <label class="bg-green-600 text-black p-1 m-2">Money</label>
    <input
      placeholder="Amount of Money"
      class="text-black border-2 border-black"
      type="number"
      v-model="money"
    />
    <label class="bg-green-600 text-black p-1 m-2">Months</label>
    <input
      placeholder="Number of Months"
      class="text-black border-2 border-black"
      type="number"
      v-model="months"
    />
    <label class="bg-green-600 text-black p-1 m-2">Monthly Budget</label>
    <p class="bg-blue-300 border-black border-2 p-2 text-black m-3">
      ${{ month_budg }}
    </p>
  </div>
  <div class="flex flex-col items-center justify-center w-96 mx-auto">
    <label class="block text-center bg-green-600 w-full">Categories</label>
    <div class="flex w-full gap4 mb-4">
      <button @click="addrow" class="border-2 bg-green-400 border-black flex-1">
        Add Row
      </button>
      <button
        @click="deleterow(index)"
        class="border-2 bg-red-400 border-black flex-1"
      >
        Delete Row
      </button>
      <button
        @click="resetrows"
        class="border-2 bg-yellow-400 border-black flex-1"
      >
        Reset Rows
      </button>
    </div>
    <div
      v-for="(rows, index) in rows"
      :key="index"
      class="flex justify-between gap-7"
    >
      <input
        v-model="rows.category"
        placeholder="Category"
        class="border-2 border-black"
      />
      <input
        v-model="rows.percentage"
        placeholder="Percent"
        class="border-2 border-black"
      />
    </div>
  </div>
</template>
