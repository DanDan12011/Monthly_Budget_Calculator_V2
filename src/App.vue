<script>
export default {
  data() {
    return {
      money: localStorage.getItem('money') ? JSON.parse(localStorage.getItem('money')) : null,
      months: localStorage.getItem('months') ? JSON.parse(localStorage.getItem('months')) : null,
      rows: localStorage.getItem('rows') ? JSON.parse(localStorage.getItem('rows')) : [{ category: "", percentage: "", amountspent: "", totalSpent: 0 }],
      showhistory: false,
      expenses: localStorage.getItem('expenses') ? JSON.parse(localStorage.getItem('expenses')) : 0,
    };
  },
  computed: {
    month_budg() {
      if (this.money > 0 && this.months > 0) {
        return (Math.round((this.money / this.months)) * 100 / 100) - this.expenses;
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
  watch: {
    money(newValue) {
      localStorage.setItem('money', JSON.stringify(newValue));
    },
    months(newValue) {
      localStorage.setItem('months', JSON.stringify(newValue));
    },
    rows: {
      handler(newValue) {
        localStorage.setItem('rows', JSON.stringify(newValue));
      },
      deep: true
    },
    expenses(newValue) {
      localStorage.setItem('expenses', JSON.stringify(newValue));
    }
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
      row.totalSpent += amount;
      this.expenses += amount;
      this.month_budg -= amount;
      row.amountspent = ""; // Clear input after adding
    },
    new_month() {
      if (this.months <= 0) {
        alert("You have reached the end of your entered months. Enter more months");
      }
      else {
        this.money -= this.expenses;
        this.months -= 1;
        this.expenses = 0;
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
    <h1 class="font-bold">Monthly Budget Calculator</h1>
    <label class="bg-green-600 text-black p-1 w-full block text-center font-bold">Money</label>
    <input placeholder="Amount of Money"
      class="p-2 text-black rounded-none border border-black block text-center w-full" type="number" v-model="money" />
    <label class=" font-bold bg-green-600 text-black p-1 w-full block text-center">Months</label>
    <input placeholder="Number of Months"
      class="p-2 text-black rounded-none  border border-black w-full block text-center" type="number"
      v-model="months" />
    <label class=" font-bold bg-green-600 text-black p-1 w-full block text-center ">Monthly Budget</label>

    <!-- show month budg, or say to enter money or months, or congratulate on savings -->
    <div v-if="money && months > 0" class="bg-green-200 rounded-none border-black border-2 w-full text-center p-4">
      <h3>Total Money: {{ money }}</h3>
      <p class="font-bold text-2xl"> Monthly Budget:
        ${{ month_budg }}
      </p>
      <h3>Months Left: {{ months }}</h3>
    </div>
    <div v-if="!money && !months" class="bg-green-200 rounded-none border-black border-2 w-full text-center p-4">
      <h3>Enter Money and Months</h3>
    </div>
    <div v-if="money > 0 && months == 0"
      class="bg-green-200 rounded-none  border-black border-2 w-full text-center p-4">
      <h3>You saved ${{ money }}!</h3>
    </div>

    <!-- categories and percentages -->
    <div class="flex justify-between w-full">
      <label class="block text-center bg-blue-400 w-full font-bold p-3 text-lg">Categories</label>
      <label class="block text-center bg-blue-400 w-full font-bold p-3 text-lg">%: {{ percent_pool }}</label>
    </div>
    <div class="flex justify-between w-full">

      <!-- add, delete, reset buttons -->
      <button @click="addrow" class="rounded-none border-2 bg-green-400 border-black flex-1 p-2">
        Add Row
      </button>
      <button @click="deleterow(index)" class="rounded-none border-2 bg-red-400 border-black flex-1 p-2">
        Delete Row
      </button>
      <button @click="resetrows" class="rounded-none border-2 bg-yellow-400 border-black flex-1 p-2">
        Reset
      </button>
      <button @click="new_month" class="rounded-none border-2 bg-purple-400 border-black flex-1 p-2">New Month</button>
    </div>

    <!-- rows for each category and percentage -->
    <div v-for="(rows, index) in rows" :key="index" class="flex justify-between w-full">
      <input v-model="rows.category" placeholder="Category" type="text"
        class="p-2 rounded-none border-2 border-black w-full" />
      <input v-model.number="rows.percentage" placeholder="Percent" type="number"
        class="p-2 rounded-none border-2 border-black w-full" @input="limitpercentage(rows)" />
    </div>

    <!-- spendings  -->
    <label class="block text-center bg-orange-400 w-full font-bold">Spendings</label>
    <div v-for="(budget, index) in category_budg" :key="'budget-' + index" class="flex justify-between w-full">
      <p class="w-full bg-orange-100" v-if="budget.category && budget.budg > 0">
        {{ budget.category }}: ${{ (budget.budg - rows[index].totalSpent).toFixed(2) }}
      </p>
      <input v-model.number="rows[index].amountspent" type="number" v-if="budget.category && budget.budg > 0"
        class="p-2 w-full rounded-none border-2 border-red-500" placeholder="Amount Spent" />
      <button v-if="budget.category && budget.budg > 0"
        class="bg-red-500 rounded-none border-2 border-red-500 text-lg font-bold p-2"
        @click="spendamount(rows[index])">✅</button>
    </div>

    <!-- history -->
    <label @click="showhistory = !showhistory"
      class="block text-center bg- w-full bg-indigo-400 font-bold cursor-pointer">History <span>{{ showhistory ?
        '\u25BC'
        : '\u25B6' }}</span></label>

    <div v-show="showhistory" class="w-full">
      <div v-for="(category, index) in category_budg" :key="'history-' + index"
        class="w-full rounded-none border border-black flex justify-between">
        <p v-if="rows[index].totalSpent > 0" class=" font-bold text-center w-full bg-indigo-100">{{ category.category
        }}:
        </p>
        <p v-if="rows[index].totalSpent > 0" class=" text-center w-full bg-indigo-100">-${{ rows[index].totalSpent }}
        </p>
      </div>
    </div>

  </div>
</template>
