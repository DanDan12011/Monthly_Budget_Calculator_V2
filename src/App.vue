<script>
export default {
  data() {
    return {
      money: null,
      months: null,
      rows: [{ category: "", percentage: "" }],
    };
  },
  computed: {
    month_budg() {
      if (this.money > 0 && this.months > 0) {
        return Math.round((this.money / this.months) * 100) / 100;
      } else {
        return 0;
      }
    },
    category_budg() {
      return this.rows.map((row) => {
        if (row.category && row.percentage) {
          const percentage = parseFloat(row.percentage) || 0;

          const allocatedBudget = parseFloat(
            (percentage / 100) * this.month_budg
          );

          return {
            category: row.category,
            budg: allocatedBudget.toFixed(2),
          };
        } else {
          return {
            category: "",
            budg: 0,
          };
        }
      });
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
  <div class="flex flex-col items-center justify-center w-96 mx-auto ">
    <h1 class="text-lg font-bold">Monthly Budget Calculator</h1>
    <label class="bg-green-600 text-black p-1 w-full block text-center font-bold"
      >Money</label
    >
    <input
      placeholder="Amount of Money"
      class="text-black border-2 border-black block text-center w-full"
      type="number"
      v-model="money"
    />
    <label class=" font-bold bg-green-600 text-black p-1 w-full block text-center"
      >Months</label
    >
    <input
      placeholder="Number of Months"
      class="text-black border-2 border-black w-full block text-center"
      type="number"
      v-model="months"
    />
    <label class=" font-bold bg-green-600 text-black p-1 w-full block text-center"
      >Monthly Budget</label
    >
    <p
      class="bg-green-200 border-black border-2 p-2 text-black w-full block text-center"
    >
      ${{ month_budg }}
    </p>
  </div>

  <!-- categories and percentages -->
  <div class="flex flex-col items-center justify-center w-96 mx-auto">
    <label class="block text-center bg-blue-400 w-full font-bold">Categories</label>
    <div class="flex w-full gap4">
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
        Reset
      </button>
    </div>

    <!-- rows for each category and percentage -->
    <div
      v-for="(rows, index) in rows"
      :key="index"
      class="flex justify-between w-full"
    >
      <input
        v-model="rows.category"
        placeholder="Category"
        class="border-2 border-black w-full"
      />
      <input
        v-model.number="rows.percentage"
        placeholder="Percent"
        type="number"
        class="border-2 border-black w-full"
      />
    </div>

    <label class="block text-center bg-orange-400 w-full font-bold">Spendings</label>
    <div
      v-for="(budget, index) in category_budg"
      :key="'budget- ' + index"
      class="flex justify-between w-full"
      
    >
      <p class="w-full bg-orange-100" v-if="budget.category && budget.budg > 0">
        {{ budget.category }}: ${{ budget.budg }}
      </p>
      <input v-if="budget.category && budget.budg > 0" class="w-full border-2 border-red-500" placeholder="Amount Spent"></input>
      <button v-if="budget.category && budget.budg > 0" class="bg-red-500 border-2 border-red-500 text-lg">&#x2705</button>
    </div>
  </div>
</template>
