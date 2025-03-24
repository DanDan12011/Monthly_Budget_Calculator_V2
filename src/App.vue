<script>
export default {
  data() {
    return {
      money: null,
      months: null,
      rows: [{ category: "", percentage: "", amountspent: "", totalSpent: 0 }],
      showhistory: false,
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
          const allocatedBudget = (percentage / 100) * this.month_budg;
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
    percent_pool() {
      return this.rows.reduce((total, row) => total + (parseFloat(row.percentage) || 0), 0);
    },
  },
  methods: {
    addrow() {
      this.rows.push({ category: "", percentage: "", amountspent: "", totalSpent: 0 });
    },
    deleterow(index) {
      if (this.rows.length > 1) {
        this.rows.splice(index, 1);
      }
    },
    resetrows() {
      this.rows = [{ category: "", percentage: "", amountspent: "", totalSpent: 0 }];
    },
    limitpercentage(row) {
      if (this.percent_pool > 100) {
        alert("Exceeded 100% of budget");
        row.percentage = "";
      }
    },
    spendamount(row) {
      const amount = parseFloat(row.amountspent) || 0;
      if (amount >= 0) {
        row.totalSpent += amount;
        row.amountspent = ""; // Clear input after adding
      } else {
        alert("Invalid spent amount");
      }
    },
  },
};
</script>

<template>
  <!-- money and months input -->
  <div class="flex flex-col items-center justify-center w-full mx-auto">
    <h1 class="text-lg font-bold">Monthly Budget Calculator</h1>
    <label class="bg-green-600 text-black p-1 w-full block text-center font-bold">Money</label>
    <input placeholder="Amount of Money" class="text-black border-2 border-black block text-center w-full" type="number"
      v-model="money" />
    <label class=" font-bold bg-green-600 text-black p-1 w-full block text-center">Months</label>
    <input placeholder="Number of Months" class="text-black border-2 border-black w-full block text-center"
      type="number" v-model="months" />
    <label class=" font-bold bg-green-600 text-black p-1 w-full block text-center">Monthly Budget</label>
    <p class="bg-green-200 border-black border-2 p-2 text-black w-full block text-center">
      ${{ month_budg }}
    </p>

    <!-- categories and percentages -->
    <div class="flex justify-between w-full">
      <label class="block text-center bg-blue-400 w-full font-bold">Categories</label>
      <label class="block text-center bg-blue-400 w-full font-bold">%: {{ percent_pool }}</label>
    </div>
    <div class="flex w-full">
      <!-- add, delete, reset buttons -->
      <button @click="addrow" class="border-2 bg-green-400 border-black flex-1 p-2">
        Add Row
      </button>
      <button @click="deleterow(index)" class="border-2 bg-red-400 border-black flex-1 p-2">
        Delete Row
      </button>
      <button @click="resetrows" class="border-2 bg-yellow-400 border-black flex-1 p-2">
        Reset
      </button>
    </div>
    <!-- rows for each category and percentage -->
    <div v-for="(rows, index) in rows" :key="index" class="flex justify-between w-full">
      <input v-model="rows.category" placeholder="Category" class="border-2 border-black w-full" />
      <input v-model.number="rows.percentage" placeholder="Percent" type="number" class="border-2 border-black w-full"
        @input="limitpercentage(rows)" />
    </div>
    <!-- spendings  -->
    <label class="block text-center bg-orange-400 w-full font-bold">Spendings</label>
    <div v-for="(budget, index) in category_budg" :key="'budget-' + index" class="flex justify-between w-full">
      <p class="w-full bg-orange-100" v-if="budget.category && budget.budg > 0">
        {{ budget.category }}: ${{ (budget.budg - rows[index].totalSpent).toFixed(2) }}
      </p>
      <input v-model.number="rows[index].amountspent" type="number" v-if="budget.category && budget.budg > 0"
        class="w-full border-2 border-red-500" placeholder="Amount Spent" />
      <button v-if="budget.category && budget.budg > 0" class="bg-red-500 border-2 border-red-500 text-lg"
        @click="spendamount(rows[index])">&#x2705;</button>
    </div>
    <!-- history -->
    <label @click="showhistory = !showhistory"
      class="block text-center bg- w-full bg-indigo-400 font-bold cursor-pointer">History <span>{{ showhistory ?
        '\u25BC'
        : '\u25B6' }}</span></label>

    <div v-show="showhistory" class="w-full">
      <div v-for="(category, index) in category_budg" :key="'history-' + index"
        class="w-full border-2 border-black flex justify-between">
        <p v-if="rows[index].totalSpent > 0" class=" font-bold text-center w-full bg-indigo-100">{{ category.category
          }}:
        </p>
        <p class=" text-center w-full bg-indigo-100">-${{ rows[index].totalSpent }}</p>
      </div>
    </div>

  </div>
</template>
