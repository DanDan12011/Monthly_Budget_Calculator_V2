<script>
export default {
  data() {
    return {
      money: null,
      months: null,
      rows: [{ category: "", percentage: "", amountspent: "", totalSpent: 0 }],
      showhistory: false,
      remainingbudget: 0,
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
        this.rows.pop()
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
      this.remainingbudget = this.month_budg

      row.totalSpent += amount;
      this.remainingbudget -= amount;
      row.amountspent = ""; // Clear input after adding


    },
    new_month() {
      if (this.months <= 0) {
        alert("You have reached the end of your entered months. Enter more months");
      }
      else {
        this.money -= this.month_budg;
        this.months -= 1;
        this.rows.forEach(row => {
          row.amountspent = "";
          row.totalSpent = 0;
        });
      }
    }
  },
};
</script>

<template>
  <!-- money and months input -->
  <div class="flex flex-col items-center justify-center w-full">
    <h1 class="text-lg font-bold">Monthly Budget Calculator</h1>
    <label class="bg-green-600 text-black p-1 w-full block text-center font-bold">Money</label>
    <input placeholder="Amount of Money" class="p-2 text-black border-2 border-black block text-center w-full"
      type="number" v-model="money" />
    <label class=" font-bold bg-green-600 text-black p-1 w-full block text-center">Months</label>
    <input placeholder="Number of Months" class="p-2 text-black border-2 border-black w-full block text-center"
      type="number" v-model="months" />
    <label class=" font-bold bg-green-600 text-black p-1 w-full block text-center ">Monthly Budget</label>
    <p class="bg-green-200 border-black border-2 p-4 text-black w-full block text-center text-2xl font-bold">
      ${{ month_budg }}
    </p>

    <!-- categories and percentages -->
    <div class="flex justify-between w-full">
      <label class="block text-center bg-blue-400 w-full font-bold p-3 text-lg">Categories</label>
      <label class="block text-center bg-blue-400 w-full font-bold p-3 text-lg">%: {{ percent_pool }}</label>
    </div>
    <div class="flex justify-between w-full">
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
      <button @click="new_month" class="border-2 bg-purple-400 border-black flex-1 p-2">New Month</button>
    </div>
    <!-- rows for each category and percentage -->
    <div v-for="(rows, index) in rows" :key="index" class="flex justify-between w-full">
      <input v-model="rows.category" placeholder="Category" type="text" class="p-2 border-2 border-black w-full" />
      <input v-model.number="rows.percentage" placeholder="Percent" type="number"
        class="p-2 border-2 border-black w-full" @input="limitpercentage(rows)" />
    </div>
    <!-- spendings  -->
    <label class="block text-center bg-orange-400 w-full font-bold">Spendings</label>
    <div v-for="(budget, index) in category_budg" :key="'budget-' + index" class="flex justify-between w-full">
      <p class="w-full bg-orange-100" v-if="budget.category && budget.budg > 0">
        {{ budget.category }}: ${{ (budget.budg - rows[index].totalSpent).toFixed(2) }}
      </p>
      <input v-model.number="rows[index].amountspent" type="number" v-if="budget.category && budget.budg > 0"
        class="p-2 w-full border-2 border-red-500" placeholder="Amount Spent" />
      <button v-if="budget.category && budget.budg > 0" class="bg-red-500 border-2 border-red-500 text-lg font-bold p-2"
        @click="spendamount(rows[index])">🗸</button>
    </div>
    <!-- history -->
    <label @click="showhistory = !showhistory"
      class="block text-center bg- w-full bg-indigo-400 font-bold cursor-pointer">History <span>{{ showhistory ?
        '\u25BC'
        : '\u25B6' }}</span></label>

    <div v-show="showhistory" class="w-full">
      <div v-for="(category, index) in category_budg" :key="'history-' + index"
        class="w-full border border-black flex justify-between">
        <p v-if="rows[index].totalSpent > 0" class=" font-bold text-center w-full bg-indigo-100">{{ category.category
          }}:
        </p>
        <p v-if="rows[index].totalSpent > 0" class=" text-center w-full bg-indigo-100">-${{ rows[index].totalSpent }}
        </p>
      </div>
    </div>

  </div>
</template>
