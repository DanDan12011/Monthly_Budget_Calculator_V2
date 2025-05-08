<script>
export default {
  data() {
    return {
      // Get localStorage data or initialize default values
      money: localStorage.getItem("money")
        ? JSON.parse(localStorage.getItem("money"))
        : null,
      months: localStorage.getItem("months")
        ? JSON.parse(localStorage.getItem("months"))
        : null,
      rows: localStorage.getItem("rows")
        ? JSON.parse(localStorage.getItem("rows"))
        : [
            {
              category: "",
              percentage: "",
              amountspent: "",
              totalSpent: 0,
              spendHistory: [],
            },
          ],
      showhistory: false,
      expenses: localStorage.getItem("expenses")
        ? JSON.parse(localStorage.getItem("expenses"))
        : 0,
    };
  },
  computed: {
    // Monthly budget = total money / months - current expenses
    month_budg() {
      if (this.money > 0 && this.months > 0) {
        return parseFloat(
          (this.money / this.months - this.expenses).toFixed(2)
        );
      } else {
        return 0;
      }
    },
    // Calculate each category's budget based on percentage
    category_budg() {
      return this.rows.map((row) => {
        if (row.category && row.percentage) {
          const percentage = parseFloat(row.percentage) || 0;
          const allocatedBudget =
            (percentage / 100) * (this.money / this.months); // base it on raw monthly split
          const remainingBudget = allocatedBudget - row.totalSpent; // subtract only this category's spending
          return {
            category: row.category,
            budg: parseFloat(remainingBudget.toFixed(2)),
          };
        } else {
          return {
            category: "",
            budg: 0,
          };
        }
      });
    },

    // Total percentage from all rows
    percent_pool() {
      return parseFloat(
        this.rows
          .reduce((total, row) => total + (parseFloat(row.percentage) || 0), 0)
          .toFixed(2)
      );
    },
  },
  watch: {
    // Sync changes to localStorage
    money(newValue) {
      localStorage.setItem("money", JSON.stringify(newValue));
    },
    months(newValue) {
      localStorage.setItem("months", JSON.stringify(newValue));
    },
    rows: {
      handler(newValue) {
        localStorage.setItem("rows", JSON.stringify(newValue));
      },
      deep: true,
    },
    expenses(newValue) {
      localStorage.setItem("expenses", JSON.stringify(newValue));
    },
  },
  methods: {
    // Add new category row
    addrow() {
      this.rows.push({
        category: "",
        percentage: "",
        amountspent: "",
        totalSpent: 0,
        spendHistory: [],
      });
    },
    // Delete last row (if more than one)
    deleterow(index) {
      if (this.rows.length > 1) {
        this.rows.pop();
      }
    },
    // Reset all values and clear localStorage
    resetall() {
      const confirmReset = confirm(
        "Are you sure you want to reset? Everything will be set to 0."
      );
      if (!confirmReset) return;
      localStorage.removeItem("money");
      localStorage.removeItem("months");
      localStorage.removeItem("rows");
      localStorage.removeItem("expenses");
      console.log("LocalStorage cleared");

      this.money = 0;
      this.months = 0;
      this.expenses = 0;
      this.rows = [
        {
          category: "",
          percentage: 0,
          amountspent: 0,
          totalSpent: 0,
          spendHistory: [],
        },
      ];
      this.$nextTick(() => {
        console.log("After reset:");
        console.log("money:", this.money);
        console.log("months:", this.months);
        console.log("expenses:", this.expenses);
        console.log("rows:", this.rows);
      });
    },
    // Limit total percentage to 100%
    limitpercentage(row) {
      if (this.percent_pool > 100) {
        alert("Exceeded 100% of budget");
        row.percentage = "";
      }
    },
    // Spend amount in category and log history
    spendamount(row) {
      const amount = parseFloat(row.amountspent) || 0;
      if (amount <= 0) return;

      if (!row.spendHistory) row.spendHistory = [];
      row.spendHistory.push(amount);

      // ✅ Update only this row's total spent
      row.totalSpent = parseFloat(
        row.spendHistory.reduce((a, b) => a + b, 0).toFixed(2)
      );

      // ✅ Update the global expense by recalculating just for this row
      this.expenses = parseFloat((this.expenses + amount).toFixed(2));

      row.amountspent = "";
    },

    // Start new month
    new_month() {
      if (this.months <= 0) {
        alert(
          "You have reached the end of your entered months. Enter more months"
        );
      } else {
        this.money = parseFloat((this.money - this.expenses).toFixed(2));
        this.months -= 1;
        this.expenses = 0;
        this.rows.forEach((row) => {
          row.amountspent = "";
          row.totalSpent = 0;
          row.spendHistory = [];
        });
      }
    },
  },
};
</script>

<template>
  <!-- title -->
  <div class="flex flex-col items-center m-2">
    <h1 class="font-bold">Monthly Budget Calculator</h1>
    <!-- enter money -->
    <label
      class="bg-green-600 text-black p-1 w-full block text-center font-bold"
      >Money</label
    >
    <input
      placeholder="Amount of Money"
      class="p-2 text-black rounded-none border border-black block text-center w-full"
      type="number"
      v-model="money"
    />
    <label
      class="font-bold bg-green-600 text-black p-1 w-full block text-center"
      >Months</label
    >
    <!-- enter months -->
    <input
      placeholder="Number of Months"
      class="p-2 text-black rounded-none border border-black w-full block text-center"
      type="number"
      v-model="months"
    />
    <!-- show month budg -->
    <label
      class="font-bold bg-green-600 text-black p-1 w-full block text-center"
      >Monthly Budget</label
    >

    <div
      v-if="money && months > 0"
      class="bg-green-200 rounded-none border-black border-2 w-full text-center p-4"
    >
      <h3>Total Money: ${{ parseFloat(money).toFixed(2) }}</h3>
      <p class="font-bold text-2xl">
        Monthly Budget: ${{ month_budg.toFixed(2) }}
      </p>
      <h3>Months Left: {{ months }}</h3>
    </div>
    <div
      v-if="!money || !months"
      class="bg-green-200 rounded-none border-black border-2 w-full text-center p-4"
    >
      <h3>Enter Money and Months</h3>
    </div>

    <!-- categories bar -->
    <div class="flex justify-between w-full">
      <label class="block text-center bg-blue-400 w-full font-bold p-3 text-lg"
        >Categories</label
      >
      <label class="block text-center bg-blue-400 w-full font-bold p-3 text-lg"
        >%: {{ percent_pool }}</label
      >
    </div>
    <div class="flex justify-between w-full">
      <button
        @click="addrow"
        class="rounded-none border-2 bg-green-400 border-black flex-1 p-2"
      >
        Add Row
      </button>
      <button
        @click="deleterow(index)"
        class="rounded-none border-2 bg-red-400 border-black flex-1 p-2"
      >
        Delete Row
      </button>
      <button
        @click="resetall"
        class="rounded-none border-2 bg-yellow-400 border-black flex-1 p-2"
      >
        Reset
      </button>
      <button
        @click="new_month"
        class="rounded-none border-2 bg-purple-400 border-black flex-1 p-2"
      >
        New Month
      </button>
    </div>

    <div
      v-for="(rows, index) in rows"
      :key="index"
      class="flex justify-between w-full"
    >
      <input
        v-model="rows.category"
        placeholder="Category"
        type="text"
        class="p-2 rounded-none border-2 border-black w-full"
      />
      <input
        v-model.number="rows.percentage"
        placeholder="Percent"
        type="number"
        class="p-2 rounded-none border-2 border-black w-full"
        @input="limitpercentage(rows)"
      />
    </div>

    <!-- spendings -->
    <label class="block text-center bg-orange-400 w-full font-bold"
      >Spendings</label
    >
    <div
      v-for="(budget, index) in category_budg"
      :key="'budget-' + index"
      class="flex justify-between w-full"
    >
      <p class="w-full bg-orange-100" v-if="budget.category && budget.budg > 0">
        {{ budget.category }}: ${{
          (budget.budg - rows[index].totalSpent).toFixed(2)
        }}
      </p>
      <input
        v-model.number="rows[index].amountspent"
        type="number"
        v-if="budget.category && budget.budg > 0"
        class="p-2 w-full rounded-none border-2 border-red-500"
        placeholder="Amount Spent"
      />
      <button
        v-if="budget.category && budget.budg > 0"
        class="bg-red-500 rounded-none border-2 border-red-500 text-lg font-bold p-2"
        @click="spendamount(rows[index])"
      >
        <i class="fas fa-check"></i>
      </button>
    </div>
    <!-- history -->
    <label
      @click="showhistory = !showhistory"
      class="block text-center w-full bg-indigo-400 font-bold cursor-pointer"
    >
      History
      <i
        :class="showhistory ? 'fa-solid fa-caret-up' : 'fa-solid fa-caret-down'"
      ></i>
    </label>

    <div v-show="showhistory" class="w-full">
      <div
        v-for="(row, rowIndex) in rows"
        :key="'row-history-' + rowIndex"
        class="w-full"
      >
        <div
          v-if="row.spendHistory?.length > 0"
          class="font-bold text-center bg-indigo-200"
        >
          {{ row.category }}
        </div>
        <div
          v-for="(amount, i) in row.spendHistory"
          :key="'spend-' + i"
          class="w-full rounded-none border-b border-black text-center bg-indigo-100"
        >
          - ${{ amount.toFixed(2) }}
        </div>
      </div>
    </div>
  </div>
</template>
