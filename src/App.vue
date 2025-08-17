<script>
export default {
  data() {
    return {
      money: localStorage.getItem("money")
        ? parseFloat(JSON.parse(localStorage.getItem("money")))
        : 0,
      months: localStorage.getItem("months")
        ? parseInt(JSON.parse(localStorage.getItem("months")))
        : 0,
      rows: localStorage.getItem("rows")
        ? JSON.parse(localStorage.getItem("rows")).map((row) => ({
            ...row,
            category: row.category || "",
            percentage: row.percentage || "",
            itemname: row.itemname || "",
            amountspent: row.amountspent || "",
            spendHistory: Array.isArray(row.spendHistory)
              ? row.spendHistory
              : [],
            totalSpent: parseFloat(row.totalSpent) || 0,
          }))
        : [
            {
              category: "",
              percentage: "",
              itemname: "",
              amountspent: "",
              totalSpent: 0,
              spendHistory: [],
            },
          ],
      showhistory: false,
      expenses: localStorage.getItem("expenses")
        ? parseFloat(JSON.parse(localStorage.getItem("expenses")))
        : 0,
      errorMessage: "",
    };
  },
  computed: {
    month_budg() {
      if (this.money > 0 && this.months > 0) {
        return parseFloat((this.money / this.months).toFixed(2));
      } else {
        return 0;
      }
    },
    category_budg() {
      return this.rows.map((row) => {
        if (row.category && row.percentage) {
          const percentage = parseFloat(row.percentage) || 0;
          const allocatedBudget =
            (percentage / 100) * (this.money / this.months);
          const remainingBudget = allocatedBudget - row.totalSpent;
          return {
            category: row.category,
            budg: parseFloat(remainingBudget.toFixed(2)),
            rowIndex: this.rows.indexOf(row),
          };
        } else {
          return {
            category: "",
            budg: 0,
            rowIndex: -1,
          };
        }
      });
    },
    percent_pool() {
      return parseFloat(
        this.rows
          .reduce((total, row) => total + (parseFloat(row.percentage) || 0), 0)
          .toFixed(2)
      );
    },
    canAddMorePercentage() {
      return this.percent_pool < 100;
    },
  },
  watch: {
    // Sync changes to localStorage
    money(newValue) {
      localStorage.setItem("money", JSON.stringify(newValue));
      console.log("Saved: ", newValue);
    },
    months(newValue) {
      localStorage.setItem("months", JSON.stringify(newValue));
      console.log("Saved: ", newValue);
    },
    rows: {
      handler(newValue) {
        localStorage.setItem("rows", JSON.stringify(newValue));
        console.log("Saved: ", newValue);
      },
      deep: true,
    },
    expenses(newValue) {
      localStorage.setItem("expenses", JSON.stringify(newValue));
      console.log("Saved: ", newValue);
    },
  },
  methods: {
    addrow() {
      this.rows.push({
        category: "",
        percentage: "",
        itemname: "",
        amountspent: "",
        totalSpent: 0,
        spendHistory: [],
      });
    },
    deleterow() {
      if (this.rows.length > 1) {
        this.rows.splice(this.rows.length - 1, 1);
        console.log("deleted row: ", this.rows.length);
      }
    },
    resetall() {
      const confirmReset = confirm(
        "Are you sure you want to reset? Everything will be set to 0."
      );
      if (!confirmReset) return;

      try {
        localStorage.removeItem("money");
        localStorage.removeItem("months");
        localStorage.removeItem("rows");
        localStorage.removeItem("expenses");

        this.money = 0;
        this.months = 0;
        this.expenses = 0;
        this.rows = [
          {
            category: "",
            percentage: "",
            itemname: "",
            amountspent: "",
            totalSpent: 0,
            spendHistory: [],
          },
        ];
        this.errorMessage = "";
        localStorage.setItem("rows", JSON.stringify(this.rows));
      } catch (error) {
        console.error("Error during reset:", error);
        this.errorMessage = "Error during reset. Please try again.";
      }
    },
    limitpercentage(row) {
      const currentPercentage = parseFloat(row.percentage) || 0;
      const otherPercentages = this.rows
        .filter((r) => r !== row)
        .reduce((total, r) => total + (parseFloat(r.percentage) || 0), 0);

      if (otherPercentages + currentPercentage > 100) {
        this.errorMessage = "Total percentage cannot exceed 100%";
        row.percentage = "";
        setTimeout(() => {
          this.errorMessage = "";
        }, 3000);
        return false;
      }
      return true;
    },

    spendamount(row) {
      const amount = parseFloat(row.amountspent);
      const item = row.itemname;

      if (isNaN(amount) || amount <= 0) {
        this.errorMessage = "Please enter a valid amount";
        row.amountspent = "";
        setTimeout(() => {
          this.errorMessage = "";
        }, 3000);
        return;
      }

      if (!item || item.trim() === "") {
        this.errorMessage = "Please enter an item name";
        setTimeout(() => {
          this.errorMessage = "";
        }, 3000);
        return;
      }

      // Check if spending exceeds budget
      const percentage = parseFloat(row.percentage) || 0;
      const allocatedBudget = (percentage / 100) * (this.money / this.months);
      const remainingBudget = allocatedBudget - row.totalSpent;

      if (amount > remainingBudget) {
        this.errorMessage = `Spending amount exceeds remaining budget for ${row.category}`;
        setTimeout(() => {
          this.errorMessage = "";
        }, 3000);
        return;
      }

      if (!row.spendHistory) row.spendHistory = [];

      // Add the new spending item
      row.spendHistory.push({
        item: item.trim(),
        amount: parseFloat(amount.toFixed(2)),
        date: new Date().toLocaleDateString(),
      });

      // Calculate the total for just this row
      row.totalSpent = row.spendHistory.reduce((a, b) => a + b.amount, 0);

      // Update total expenses
      this.expenses = this.rows.reduce((total, r) => total + r.totalSpent, 0);

      // Clear the inputs
      row.amountspent = "";
      row.itemname = "";

      this.errorMessage = "";
    },

    new_month() {
      if (this.months <= 0) {
        this.errorMessage =
          "You have reached the end of your entered months. Enter more months";
        setTimeout(() => {
          this.errorMessage = "";
        }, 3000);
        return;
      }

      if (this.money < this.expenses) {
        this.errorMessage = "Not enough money left for this month";
        setTimeout(() => {
          this.errorMessage = "";
        }, 3000);
        return;
      }

      const confirmNewMonth = confirm(
        `Start a new month?\n\n` +
          `This will:\n` +
          `• Carry over $${(this.money - this.expenses).toFixed(
            2
          )} to next month\n` +
          `• Reset all spending for the new month\n` +
          `• Decrease months left from ${this.months} to ${
            this.months - 1
          }\n\n` +
          `Do you want to continue?`
      );

      if (!confirmNewMonth) return;

      // Carry over leftover money to next month
      this.money = parseFloat((this.money - this.expenses).toFixed(2));
      this.months -= 1;
      this.expenses = 0;

      // Clear spending data for the new month
      this.rows.forEach((row) => {
        row.amountspent = "";
        row.totalSpent = 0;
        row.spendHistory = [];
      });

      this.errorMessage = "";
    },

    deleteHistoryEntry(row, index) {
      const entry = row.spendHistory[index];
      row.spendHistory.splice(index, 1);
      row.totalSpent = parseFloat(
        row.spendHistory.reduce((a, b) => a + b.amount, 0).toFixed(2)
      );
      this.expenses = parseFloat((this.expenses - entry.amount).toFixed(2));
    },

    clearError() {
      this.errorMessage = "";
    },
  },
};
</script>

<template>
  <!-- title -->
  <h1 class="font-bold flex flex-col items-center">
    Monthly Budget Calculator
  </h1>

  <!-- Error Message Display -->
  <div
    v-if="errorMessage"
    class="bg-red-500 text-white p-3 mx-auto w-[90%] mb-4 rounded text-center"
  >
    {{ errorMessage }}
    <button @click="clearError" class="ml-2 bg-red-700 px-2 py-1 rounded">
      ×
    </button>
  </div>

  <div class="flex flex-col items-center w-[90%] mx-auto border border-black">
    <!-- enter money -->
    <label
      for="money-input"
      class="bg-green-600 text-black p-1 w-full block text-center font-bold"
      >Money</label
    >
    <input
      id="money-input"
      placeholder="Amount of Money"
      class="p-2 text-black rounded-none border border-black block text-center w-full budget-input transition-all"
      type="number"
      v-model="money"
      min="0"
      step="0.01"
    />

    <label
      for="months-input"
      class="font-bold bg-green-600 text-black p-1 w-full block text-center"
      >Months</label
    >
    <!-- enter months -->
    <input
      id="months-input"
      placeholder="Number of Months"
      class="p-2 text-black rounded-none border border-black w-full block text-center budget-input transition-all"
      type="number"
      v-model="months"
      min="1"
    />

    <!-- show month budg -->
    <label
      class="font-bold bg-green-600 text-black p-1 w-full block text-center"
      >Monthly Budget</label
    >

    <div
      v-if="money && months > 0"
      class="bg-green-200 rounded-none border border-black w-full text-center p-4"
    >
      <h3>Total Money: ${{ parseFloat(money).toFixed(2) }}</h3>
      <p class="font-bold text-2xl">
        Monthly Budget: ${{ month_budg.toFixed(2) }}
      </p>
      <h3>Months Left: {{ months }}</h3>
      <p class="text-sm mt-2">
        Current Month Expenses: ${{ expenses.toFixed(2) }}
      </p>
    </div>
    <div
      v-if="!money || !months"
      class="bg-green-200 rounded-none border border-black w-full text-center p-4"
    >
      <h3>Enter Money and Months</h3>
    </div>

    <!-- categories bar -->
    <div class="flex justify-between w-full">
      <label class="block text-center bg-blue-400 w-full font-bold p-3 text-lg"
        >Categories</label
      >
      <label class="block text-center bg-blue-400 w-full font-bold p-3 text-lg">
        <span v-if="percent_pool > 100" class="text-red-600">Exceeds 100%</span>
        <span
          v-else-if="percent_pool < 100"
          :class="{
            'text-black': 100 - percent_pool >= 50,
            'text-yellow-400':
              100 - percent_pool < 50 && 100 - percent_pool >= 25,
            'text-red-600': 100 - percent_pool < 25,
          }"
        >
          {{ (100 - percent_pool).toFixed(1) }}% remaining
        </span>
        <span v-else class="text-black">100% allocated</span>
      </label>
    </div>

    <div class="flex justify-between w-full">
      <button
        @click="addrow"
        class="rounded-none border border-black bg-green-400 flex-1 p-2"
      >
        Add Row
      </button>
      <button
        @click="deleterow"
        class="rounded-none border border-black bg-red-400 flex-1 p-2"
      >
        Delete Row
      </button>
      <button
        @click="resetall"
        class="rounded-none border border-black bg-yellow-400 flex-1 p-2"
      >
        Reset
      </button>
      <button
        @click="new_month"
        class="rounded-none border border-black bg-purple-400 flex-1 p-2"
      >
        New Month
      </button>
    </div>

    <!-- Category Inputs -->
    <div
      v-if="money && months > 0"
      v-for="(row, index) in rows"
      :key="'category-' + index"
      class="flex justify-between w-full"
    >
      <input
        v-model="row.category"
        placeholder="Category"
        type="text"
        class="p-2 rounded-none border border-black w-full"
      />
      <input
        v-model.number="row.percentage"
        placeholder="Percent"
        type="number"
        class="p-2 rounded-none border border-black w-full"
        @input="limitpercentage(row)"
        min="0"
        max="100"
        step="0.1"
      />
    </div>

    <!-- spendings -->
    <label class="block text-center bg-orange-400 w-full font-bold"
      >Spendings</label
    >

    <!-- Spending inputs for each category -->
    <div
      v-for="(budget, index) in category_budg"
      :key="'budget-' + index"
      class="w-full"
    >
      <div v-if="budget.category.trim() !== ''" class="flex w-full">
        <!-- Category Budget Display -->
        <div class="bg-orange-100 p-2 border-r border-orange-300 flex-1">
          <p class="font-bold">
            {{ budget.category }}: ${{ budget.budg.toFixed(2) }}
          </p>
          <p class="text-sm text-gray-600">
            Budget: ${{
              (
                (parseFloat(rows[budget.rowIndex].percentage) / 100) *
                (money / months)
              ).toFixed(2)
            }}
          </p>
        </div>

        <!-- Spending Inputs -->
        <div class="flex justify-between w-full p-2 bg-orange-50 flex-1">
          <input
            v-model="rows[budget.rowIndex].itemname"
            class="p-2 w-full rounded-none border border-black mr-2"
            placeholder="Item name"
          />
          <input
            v-model="rows[budget.rowIndex].amountspent"
            class="p-2 w-full rounded-none border border-black mr-2"
            placeholder="Amount"
            type="number"
            min="0"
            step="0.01"
          />
          <button
            class="bg-red-500 rounded-none border border-black text-lg font-bold p-2 text-white budget-button transition-all"
            @click="spendamount(rows[budget.rowIndex])"
            :disabled="
              !rows[budget.rowIndex].itemname ||
              !rows[budget.rowIndex].amountspent
            "
          >
            <i class="fas fa-check text-black"></i>
          </button>
        </div>
      </div>
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
          class="font-bold text-center bg-indigo-200 p-2"
        >
          {{ row.category }} - Total Spent: ${{ row.totalSpent.toFixed(2) }}
        </div>
        <div
          v-for="(entry, i) in row.spendHistory"
          :key="'spend-' + i"
          class="w-full flex flex-row items-center justify-between border-b border-black bg-indigo-100 p-2"
        >
          <span class="flex-1">{{ entry.item }}</span>
          <span class="font-bold">${{ entry.amount.toFixed(2) }}</span>
          <span class="text-xs text-gray-600 mx-2">{{ entry.date }}</span>
          <button
            class="bg-red-500 px-2 py-1 ml-2 rounded text-white"
            @click="deleteHistoryEntry(row, i)"
            :aria-label="`Delete ${entry.item} spending entry`"
          >
            <i class="fa-solid fa-trash text-black"></i>
          </button>
        </div>
      </div>

      <!-- Empty state for history -->
      <div
        v-if="!rows.some((row) => row.spendHistory?.length > 0)"
        class="text-center p-4 text-gray-500"
      >
        No spending history yet. Start adding expenses above!
      </div>
    </div>
  </div>
</template>
