<script>
import { supabase } from "./supabase.js";

export default {
  data() {
    return {
      menuOpen: false,
      currentSection: "expenses",
      categories: localStorage.getItem("categories")
        ? JSON.parse(localStorage.getItem("categories"))
        : ["Food", "Transport", "Bills"],
      expenseHistory: localStorage.getItem("expenseHistory")
        ? JSON.parse(localStorage.getItem("expenseHistory"))
        : [],
      newExpenseAmount: "",
      selectedCategory: "",
      newCategoryName: "",
      historyFilter: "all",
      timeFilter: "all",
      errorMessage: "",
      nextId: localStorage.getItem("expenseNextId")
        ? parseInt(localStorage.getItem("expenseNextId"), 10)
        : 1,
      syncEnabled: false,
      syncLoading: true,
      showAuthScreen: false,
      authEmail: "",
      authPassword: "",
      authMode: "signin",
      authMessage: "",
      authLoading: false,
      userIsAnonymous: true,
    };
  },
  async mounted() {
    if (!this.isSupabaseConfigured()) {
      this.syncLoading = false;
      return;
    }
    try {
      const {
        data: { session },
      } = await supabase.auth.getSession();
      if (session?.user) {
        this.userIsAnonymous = !!session.user.is_anonymous;
        this.syncEnabled = true;
        await this.loadFromSupabase();
      } else {
        const {
          data: { user: newUser },
          error,
        } = await supabase.auth.signInAnonymously();
        if (!error && newUser) {
          this.userIsAnonymous = true;
          this.syncEnabled = true;
          await this.loadFromSupabase();
        }
      }
      supabase.auth.onAuthStateChange(async (event, newSession) => {
        if (!newSession?.user) return;
        this.userIsAnonymous = !!newSession.user.is_anonymous;
        this.syncEnabled = true;
        await this.loadFromSupabase();
        this.showAuthScreen = false;
        this.authMessage = "";
      });
    } catch (e) {
      console.warn("Supabase init failed:", e);
    }
    this.syncLoading = false;
  },
  computed: {
    categoriesForFilter() {
      const fromList = [...this.categories];
      const fromExpenses = [
        ...new Set(this.expenseHistory.map((e) => e.category).filter(Boolean)),
      ];
      const seen = new Set(fromList);
      fromExpenses.forEach((c) => {
        if (!seen.has(c)) {
          seen.add(c);
          fromList.push(c);
        }
      });
      return fromList;
    },
    filteredHistory() {
      let list = this.expenseHistory;
      if (this.historyFilter !== "all") {
        list = list.filter((e) => e.category === this.historyFilter);
      }
      if (this.timeFilter === "all") return list;
      const now = Date.now();
      const ms = { day: 1, week: 7, month: 30, "6months": 180, year: 365 };
      const days = ms[this.timeFilter] || 0;
      const cutoff = now - days * 24 * 60 * 60 * 1000;
      return list.filter((e) => {
        const t =
          e.timestamp != null ? e.timestamp : new Date(e.date).getTime();
        return !isNaN(t) && t >= cutoff;
      });
    },
  },
  watch: {
    categories: {
      handler(val) {
        localStorage.setItem("categories", JSON.stringify(val));
      },
      deep: true,
    },
    expenseHistory: {
      handler(val) {
        localStorage.setItem("expenseHistory", JSON.stringify(val));
      },
      deep: true,
    },
    nextId(val) {
      localStorage.setItem("expenseNextId", String(val));
    },
  },
  methods: {
    isSupabaseConfigured() {
      return !!supabase;
    },
    toggleMenu() {
      this.menuOpen = !this.menuOpen;
    },
    setSection(section) {
      this.currentSection = section;
      this.menuOpen = false;
    },
    async addExpense() {
      const amount = parseFloat(this.newExpenseAmount);
      if (isNaN(amount) || amount <= 0) {
        this.errorMessage = "Please enter a valid amount.";
        setTimeout(() => (this.errorMessage = ""), 3000);
        return;
      }
      if (
        !this.selectedCategory ||
        !this.categories.includes(this.selectedCategory)
      ) {
        this.errorMessage = "Please select a category.";
        setTimeout(() => (this.errorMessage = ""), 3000);
        return;
      }
      const now = new Date();
      const expense = {
        id: this.nextId++,
        amount: parseFloat(amount.toFixed(2)),
        category: this.selectedCategory,
        date: now.toLocaleDateString(),
        timestamp: now.getTime(),
      };
      if (this.syncEnabled) {
        const { id: dbId, error } = await this.addExpenseToSupabase(expense);
        if (error) {
          this.errorMessage = "Failed to save. " + (error.message || "Try again.");
          setTimeout(() => (this.errorMessage = ""), 5000);
          return;
        }
        if (typeof dbId === "string") expense.id = dbId;
      }
      this.expenseHistory.unshift(expense);
      this.newExpenseAmount = "";
      this.selectedCategory = "";
      this.errorMessage = "";
    },
    async addCategory() {
      const name = (this.newCategoryName || "").trim();
      if (!name) {
        this.errorMessage = "Enter a category name.";
        setTimeout(() => (this.errorMessage = ""), 3000);
        return;
      }
      if (this.categories.includes(name)) {
        this.errorMessage = "Category already exists.";
        setTimeout(() => (this.errorMessage = ""), 3000);
        return;
      }
      if (this.syncEnabled) {
        const err = await this.addCategoryToSupabase(name);
        if (err) {
          this.errorMessage = "Failed to save category. " + (err.message || "Try again.");
          setTimeout(() => (this.errorMessage = ""), 5000);
          return;
        }
      }
      this.categories.push(name);
      this.newCategoryName = "";
      this.errorMessage = "";
    },
    deleteCategory(name) {
      this.categories = this.categories.filter((c) => c !== name);
      if (this.syncEnabled) this.deleteCategoryFromSupabase(name);
    },
    deleteHistoryEntry(id) {
      this.expenseHistory = this.expenseHistory.filter((e) => e.id !== id);
      if (this.syncEnabled) this.deleteExpenseFromSupabase(id);
    },
    clearError() {
      this.errorMessage = "";
    },
    openAuth() {
      this.showAuthScreen = true;
      this.authMessage = "";
      this.authEmail = "";
      this.authPassword = "";
      this.authMode = "signin";
    },
    closeAuth() {
      this.showAuthScreen = false;
      this.authMessage = "";
      this.authPassword = "";
      this.authLoading = false;
    },
    async submitAuth() {
      const email = (this.authEmail || "").trim().toLowerCase();
      const password = this.authPassword || "";
      if (!email) {
        this.authMessage = "Enter your email address.";
        return;
      }
      if (!password) {
        this.authMessage = "Enter your password.";
        return;
      }
      this.authLoading = true;
      this.authMessage = "";
      try {
        if (this.authMode === "signup") {
          const { data, error } = await supabase.auth.signUp({
            email,
            password,
          });
          if (error) throw error;
          if (data.session) {
            this.userIsAnonymous = false;
            await this.loadFromSupabase();
            this.showAuthScreen = false;
          } else {
            this.authMessage =
              "Check your email to verify your account, then sign in below.";
            this.authMode = "signin";
          }
        } else {
          const { error } = await supabase.auth.signInWithPassword({
            email,
            password,
          });
          if (error) throw error;
          this.userIsAnonymous = false;
          await this.loadFromSupabase();
          this.showAuthScreen = false;
        }
      } catch (e) {
        this.authMessage =
          e?.message ||
          (this.authMode === "signup" ? "Sign up failed." : "Sign in failed.");
      }
      this.authLoading = false;
    },
    async signOut() {
      if (!supabase) return;
      this.userIsAnonymous = true;
      this.syncEnabled = false;
      this.showAuthScreen = false;
      try {
        await supabase.auth.signOut();
        const {
          data: { user },
          error,
        } = await supabase.auth.signInAnonymously();
        if (!error && user) {
          this.syncEnabled = true;
          await this.loadFromSupabase();
        }
      } catch (e) {
        console.warn("Sign out / anonymous sign-in:", e);
      }
    },
    async loadFromSupabase() {
      if (!supabase || !this.syncEnabled) return;
      const uid = (await supabase.auth.getUser()).data?.user?.id;
      if (!uid) return;
      const [catRes, expRes] = await Promise.all([
        supabase
          .from("categories")
          .select("name")
          .eq("user_id", uid)
          .order("created_at"),
        supabase
          .from("expenses")
          .select("id, amount, category, date, timestamp")
          .eq("user_id", uid)
          .order("timestamp", { ascending: false }),
      ]);
      this.categories = (catRes.data || []).map((r) => r.name);
      const expenses = (expRes.data || []).map((r) => ({
        id: r.id,
        amount: Number(r.amount),
        category: r.category,
        date: r.date,
        timestamp: r.timestamp,
      }));
      this.expenseHistory = expenses;
      if (this.categories.length === 0 && expenses.length > 0) {
        const fromExpenses = [
          ...new Set(
            expenses.map((e) => e.category).filter(Boolean),
          ),
        ];
        this.categories = fromExpenses;
        for (const name of fromExpenses) {
          await supabase
            .from("categories")
            .insert({ user_id: uid, name });
        }
      }
      const maxId = expenses.reduce(
        (m, e) => (typeof e.id === "number" && e.id > m ? e.id : m),
        0,
      );
      if (maxId > 0) this.nextId = maxId + 1;
    },
    async addExpenseToSupabase(expense) {
      if (!supabase || !this.syncEnabled) return { id: expense.id, error: null };
      const uid = (await supabase.auth.getUser()).data?.user?.id;
      if (!uid) return { id: expense.id, error: new Error("Not signed in") };
      const { data, error } = await supabase
        .from("expenses")
        .insert({
          user_id: uid,
          amount: expense.amount,
          category: expense.category,
          date: expense.date,
          timestamp: expense.timestamp,
        })
        .select("id")
        .single();
      if (error) return { id: expense.id, error };
      return { id: data.id, error: null };
    },
    async addCategoryToSupabase(name) {
      if (!supabase || !this.syncEnabled) return null;
      const uid = (await supabase.auth.getUser()).data?.user?.id;
      if (!uid) return new Error("Not signed in");
      const { error } = await supabase.from("categories").insert({ user_id: uid, name });
      return error || null;
    },
    async deleteCategoryFromSupabase(name) {
      if (!supabase || !this.syncEnabled) return;
      const uid = (await supabase.auth.getUser()).data?.user?.id;
      if (!uid) return;
      await supabase
        .from("categories")
        .delete()
        .eq("user_id", uid)
        .eq("name", name);
    },
    async deleteExpenseFromSupabase(id) {
      if (!supabase || !this.syncEnabled) return;
      if (typeof id !== "string") return;
      await supabase.from("expenses").delete().eq("id", id);
    },
  },
};
</script>

<template>
  <div class="min-h-screen bg-gray-100">
    <!-- Header with hamburger -->
    <header
      class="bg-white border-b border-black sticky top-0 z-20 flex items-center justify-between px-4 py-3"
    >
      <button
        @click="toggleMenu"
        class="p-2 border border-black rounded hover:bg-gray-100"
        aria-label="Toggle menu"
      >
        <span class="block w-6 h-0.5 bg-black mb-1"></span>
        <span class="block w-6 h-0.5 bg-black mb-1"></span>
        <span class="block w-6 h-0.5 bg-black"></span>
      </button>
      <h1 class="text-lg font-bold">Expense Tracker</h1>
      <div class="flex items-center gap-2">
        <span v-if="syncLoading" class="text-xs text-gray-500">...</span>
        <span
          v-else-if="syncEnabled"
          class="text-xs text-green-600 font-medium"
          title="Synced to cloud"
          >Synced</span
        >
        <span v-else class="w-10"></span>
      </div>
    </header>

    <!-- Hamburger menu overlay / drawer -->
    <div
      v-show="menuOpen"
      class="fixed inset-0 z-30 bg-black/30"
      @click="menuOpen = false"
    ></div>
    <nav
      :class="[
        'fixed top-0 left-0 z-40 h-full w-56 bg-white border-r border-black shadow-lg transition-transform duration-200',
        menuOpen ? 'translate-x-0' : '-translate-x-full',
      ]"
    >
      <div class="p-4 border-b border-black font-bold">Menu</div>
      <button
        @click="setSection('expenses')"
        class="w-full text-left px-4 py-3 border-b border-black hover:bg-gray-100"
      >
        Expenses
      </button>
      <button
        @click="setSection('categories')"
        class="w-full text-left px-4 py-3 border-b border-black hover:bg-gray-100"
      >
        Categories
      </button>
      <button
        @click="setSection('history')"
        class="w-full text-left px-4 py-3 border-b border-black hover:bg-gray-100"
      >
        History
      </button>
      <template v-if="isSupabaseConfigured()">
        <button
          v-if="userIsAnonymous"
          @click="openAuth"
          class="w-full text-left px-4 py-3 border-b border-black hover:bg-gray-100 font-medium"
        >
          Sign in
        </button>
        <button
          v-else
          @click="signOut"
          class="w-full text-left px-4 py-3 border-b border-black hover:bg-gray-100 font-medium text-red-600"
        >
          Sign out
        </button>
      </template>
    </nav>

    <!-- Auth modal -->
    <div
      v-if="showAuthScreen"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50"
      @click.self="closeAuth"
    >
      <div
        class="bg-white rounded-lg border border-black shadow-xl max-w-sm w-full p-6"
        @click.stop
      >
        <h2 class="text-xl font-bold mb-2">
          {{ authMode === "signup" ? "Create account" : "Sign in" }}
        </h2>
        <p class="text-sm text-gray-600 mb-4">Sync your data across devices</p>
        <div class="space-y-4">
          <div>
            <label for="auth-email" class="block text-sm font-medium mb-1"
              >Email</label
            >
            <input
              id="auth-email"
              v-model="authEmail"
              type="email"
              placeholder="you@example.com"
              class="w-full p-2 border border-black rounded"
              :disabled="authLoading"
            />
          </div>
          <div>
            <label for="auth-password" class="block text-sm font-medium mb-1"
              >Password</label
            >
            <input
              id="auth-password"
              v-model="authPassword"
              type="password"
              placeholder="••••••••"
              class="w-full p-2 border border-black rounded"
              :disabled="authLoading"
              @keyup.enter="submitAuth"
            />
          </div>
          <button
            @click="submitAuth"
            class="w-full py-2 bg-blue-500 text-white font-medium rounded border border-black hover:bg-blue-600 disabled:opacity-50"
            :disabled="authLoading"
          >
            {{ authMode === "signup" ? "Create account" : "Sign in" }}
          </button>
          <button
            @click="authMode = authMode === 'signup' ? 'signin' : 'signup'"
            class="w-full py-2 text-gray-600 hover:text-black text-sm"
          >
            {{
              authMode === "signup"
                ? "Already have an account? Sign in"
                : "Create an account"
            }}
          </button>
          <button
            @click="closeAuth"
            class="w-full py-2 text-gray-600 hover:text-black text-sm"
          >
            Continue as guest
          </button>
        </div>
        <p
          v-if="authMessage"
          class="mt-4 text-sm"
          :class="
            authMessage.includes('verify') || authMessage.includes('created')
              ? 'text-green-600'
              : 'text-red-600'
          "
        >
          {{ authMessage }}
        </p>
      </div>
    </div>

    <!-- Error message -->
    <div
      v-if="errorMessage"
      class="mx-4 mt-4 p-3 bg-red-500 text-white rounded flex items-center justify-between"
    >
      <span>{{ errorMessage }}</span>
      <button @click="clearError" class="bg-red-700 px-2 py-1 rounded">
        ×
      </button>
    </div>

    <!-- Main content -->
    <main class="p-4 max-w-xl mx-auto">
      <!-- Expenses section -->
      <section v-show="currentSection === 'expenses'" class="space-y-4">
        <h2 class="text-xl font-bold border-b border-black pb-2">
          Add expense
        </h2>
        <div class="flex flex-col sm:flex-row gap-3 items-stretch sm:items-end">
          <div class="flex-1">
            <label for="expense-amount" class="block text-sm font-medium mb-1"
              >Amount ($)</label
            >
            <input
              id="expense-amount"
              v-model="newExpenseAmount"
              type="number"
              min="0"
              step="0.01"
              placeholder="0.00"
              class="w-full p-2 border border-black rounded"
            />
          </div>
          <div class="flex-1">
            <label for="expense-category" class="block text-sm font-medium mb-1"
              >Category</label
            >
            <select
              id="expense-category"
              v-model="selectedCategory"
              class="w-full p-2 border border-black rounded bg-white"
            >
              <option value="">Select category</option>
              <option v-for="cat in categories" :key="cat" :value="cat">
                {{ cat }}
              </option>
            </select>
          </div>
          <button
            @click="addExpense"
            class="p-2 bg-green-500 text-white font-medium rounded border border-black hover:bg-green-600 disabled:opacity-50 disabled:cursor-not-allowed"
            :disabled="!newExpenseAmount || !selectedCategory"
          >
            Submit
          </button>
        </div>
        <p v-if="categories.length === 0" class="text-sm text-gray-600">
          Add categories in the Categories section first.
        </p>
      </section>

      <!-- Categories section -->
      <section v-show="currentSection === 'categories'" class="space-y-4">
        <h2 class="text-xl font-bold border-b border-black pb-2">Categories</h2>
        <div class="flex gap-2">
          <input
            v-model="newCategoryName"
            type="text"
            placeholder="New category name"
            class="flex-1 p-2 border border-black rounded"
            @keyup.enter="addCategory"
          />
          <button
            @click="addCategory"
            class="px-4 py-2 bg-blue-500 text-white font-medium rounded border border-black hover:bg-blue-600"
          >
            Add
          </button>
        </div>
        <ul class="border border-black rounded divide-y divide-black">
          <li
            v-for="cat in categories"
            :key="cat"
            class="flex items-center justify-between p-2 bg-white"
          >
            <span class="font-medium">{{ cat }}</span>
            <button
              @click="deleteCategory(cat)"
              class="text-red-600 hover:text-red-800 px-2 py-1 border border-red-500 rounded text-sm"
              aria-label="Delete category"
            >
              Delete
            </button>
          </li>
        </ul>
        <p v-if="categories.length === 0" class="text-sm text-gray-500">
          No categories yet. Add one above.
        </p>
      </section>

      <!-- History section -->
      <section v-show="currentSection === 'history'" class="space-y-4">
        <h2 class="text-xl font-bold border-b border-black pb-2">History</h2>
        <div class="mb-3">
          <span class="block text-sm font-medium mb-2">Time</span>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="opt in [
                { value: 'all', label: 'All' },
                { value: 'day', label: 'Day' },
                { value: 'week', label: 'Week' },
                { value: 'month', label: 'Month' },
                { value: '6months', label: '6 Months' },
                { value: 'year', label: 'Year' },
              ]"
              :key="'time-' + opt.value"
              @click="timeFilter = opt.value"
              :class="[
                'px-3 py-1 rounded border border-black text-sm font-medium',
                timeFilter === opt.value
                  ? 'bg-black text-white'
                  : 'bg-white hover:bg-gray-100',
              ]"
            >
              {{ opt.label }}
            </button>
          </div>
        </div>
        <div class="mb-4">
          <span class="block text-sm font-medium mb-2">Category</span>
          <div class="flex flex-wrap gap-2">
            <button
              @click="historyFilter = 'all'"
              :class="[
                'px-3 py-1 rounded border border-black text-sm font-medium',
                historyFilter === 'all'
                  ? 'bg-black text-white'
                  : 'bg-white hover:bg-gray-100',
              ]"
            >
              All
            </button>
            <button
              v-for="cat in categoriesForFilter"
              :key="'filter-' + cat"
              @click="historyFilter = cat"
              :class="[
                'px-3 py-1 rounded border border-black text-sm font-medium',
                historyFilter === cat
                  ? 'bg-black text-white'
                  : 'bg-white hover:bg-gray-100',
              ]"
            >
              {{ cat }}
            </button>
          </div>
        </div>
        <ul
          class="border border-black rounded divide-y divide-black overflow-hidden"
        >
          <li
            v-for="entry in filteredHistory"
            :key="entry.id"
            class="flex items-center justify-between p-3 bg-white"
          >
            <div>
              <span class="font-bold">${{ entry.amount.toFixed(2) }}</span>
              <span class="text-gray-600 ml-2">{{ entry.category }}</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="text-sm text-gray-500">{{ entry.date }}</span>
              <button
                @click="deleteHistoryEntry(entry.id)"
                class="text-red-600 hover:text-red-800 p-1 rounded border border-red-400"
                aria-label="Delete entry"
              >
                ×
              </button>
            </div>
          </li>
        </ul>
        <p v-if="filteredHistory.length === 0" class="text-sm text-gray-500">
          <template v-if="expenseHistory.length === 0"
            >No expenses yet.</template
          >
          <template v-else-if="historyFilter !== 'all'"
            >No expenses in this category.</template
          >
          <template v-else>No expenses in this time range.</template>
        </p>
      </section>
    </main>
  </div>
</template>
