<script>
export default {
  data() {
    return {
      money: localStorage.getItem("money")
        ? JSON.parse(localStorage.getItem("money"))
        : 0,
      months: localStorage.getItem("months")
        ? JSON.parse(localStorage.getItem("months"))
        : 0,
      rows: localStorage.getItem("rows")
        ? JSON.parse(localStorage.getItem("rows")).map((row) => ({
            ...row,
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
    };
  },
  computed: {
    month_budg() {
      if (this.money > 0 && this.months > 0) {
        return parseFloat(
          (this.money / this.months - this.expenses).toFixed(2)
        );
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
      return parseFloat(
        this.rows
          .reduce((total, row) => total + (parseFloat(row.percentage) || 0), 0)
          .toFixed(2)
      );
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
    deleterow(index) {
      if (this.rows.length > 1) {
        this.rows.splice(index, 1);
      }
    },
    resetall() {
      const confirmReset = confirm(
        "Are you sure you want to reset? Everything will be set to 0."
      );
      if (!confirmReset) return;

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
    },
    limitpercentage(row) {
      if (this.percent_pool > 100) {
        alert("Exceeded 100% of budget");
        row.percentage = "";
      }
    },

    spendamount(row) {
      const amount = parseFloat(row.amountspent);
      const item = row.itemname;

      if (isNaN(amount) || amount <= 0) {
        row.amountspent = "";
        return;
      }

      // ✅ Allow empty item names, if empty just use an empty string
      if (!item || item.trim() === "") {
        row.itemname = "";
      }

      if (!row.spendHistory) row.spendHistory = [];

      // Add the new spending item
      row.spendHistory.push({
        item: item.trim(),
        amount: parseFloat(amount.toFixed(2)),
      });

      // ✅ Calculate the total for just this row
      row.totalSpent = row.spendHistory.reduce((a, b) => a + b.amount, 0);

      // ✅ Instead of adding it again, just sum up all rows
      this.expenses = this.rows.reduce((total, r) => total + r.totalSpent, 0);

      // Clear the inputs
      row.amountspent = "";
      row.itemname = "";
    },
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
        });
      }
    },

    deleteHistoryEntry(row, index) {
      const entry = row.spendHistory[index];
      row.spendHistory.splice(index, 1);
      row.totalSpent = parseFloat(
        row.spendHistory.reduce((a, b) => a + b.amount, 0).toFixed(2)
      );
      this.expenses = parseFloat((this.expenses - entry.amount).toFixed(2));
    },
  },
};
</script>

<template>
  <!-- title -->
  <h1 class="font-bold flex flex-col items-center">
    Monthly Budget Calculator
  </h1>
  <div class="flex flex-col items-center w-[90%] mx-auto border-2 border-black">
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
      v-if="money && months > 0"
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
        {{ budget.category }}: ${{ budget.budg.toFixed(2) }}
      </p>

      <input
        v-if="budget.category && budget.budg > 0"
        v-model="rows[index].itemname"
        class="p-2 w-full rounded-none border-2 border-blue-500"
        placeholder="Item"
      />
      <input
        v-if="budget.category && budget.budg > 0"
        v-model="rows[index].amountspent"
        class="p-2 w-full rounded-none border-2 border-red-500"
        placeholder="Amount Spent"
        type="number"
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
          v-for="(entry, i) in row.spendHistory"
          :key="'spend-' + i"
          class="w-full flex flex-row items-center justify-between border-b border-black bg-indigo-100 p-2"
        >
          <span class="ml-auto">{{ entry.item }} </span>
          <span v-if="entry.item">:</span>
          <span>${{ entry.amount }}</span>
          <button
            class="bg-red-500 px-2 py-1 ml-auto rounded"
            @click="deleteHistoryEntry(row, i)"
          >
            <i class="text-black fa-solid fa-trash"></i>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
