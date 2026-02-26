<script>
import { supabase } from "./supabase.js";
import ExpensePieChart from "./ExpensePieChart.vue";

export default {
  components: { ExpensePieChart },
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
      themeBg: localStorage.getItem("themeBg") ?? "#f3f4f6",
      themeText: localStorage.getItem("themeText") ?? "#111827",
      themeSurface: localStorage.getItem("themeSurface") ?? "#ffffff",
      loadingThemeFromSupabase: false,
      themeSaveMessage: "",
      authSuccessMessage: "",
      postAuthLoading: false,
      themeSaveTimeout: null,
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
    themeBg(val) {
      localStorage.setItem("themeBg", val);
      if (this.syncEnabled && !this.loadingThemeFromSupabase)
        this.debouncedSaveTheme();
    },
    themeText(val) {
      localStorage.setItem("themeText", val);
      if (this.syncEnabled && !this.loadingThemeFromSupabase)
        this.debouncedSaveTheme();
    },
    themeSurface(val) {
      localStorage.setItem("themeSurface", val);
      if (this.syncEnabled && !this.loadingThemeFromSupabase)
        this.debouncedSaveTheme();
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
          this.errorMessage =
            "Failed to save. " + (error.message || "Try again.");
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
          this.errorMessage =
            "Failed to save category. " + (err.message || "Try again.");
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
            this.showAuthScreen = false;
            this.authLoading = false;
            this.postAuthLoading = true;
            await this.loadFromSupabase();
            this.postAuthLoading = false;
            this.authSuccessMessage = "Account created! You're signed in.";
            setTimeout(() => (this.authSuccessMessage = ""), 4000);
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
          this.showAuthScreen = false;
          this.authLoading = false;
          this.postAuthLoading = true;
          await this.loadFromSupabase();
          this.postAuthLoading = false;
          this.authSuccessMessage = "Signed in successfully!";
          setTimeout(() => (this.authSuccessMessage = ""), 4000);
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
      this.authSuccessMessage = "Signed out.";
      setTimeout(() => (this.authSuccessMessage = ""), 4000);
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
          ...new Set(expenses.map((e) => e.category).filter(Boolean)),
        ];
        this.categories = fromExpenses;
        for (const name of fromExpenses) {
          await supabase.from("categories").insert({ user_id: uid, name });
        }
      }
      const maxId = expenses.reduce(
        (m, e) => (typeof e.id === "number" && e.id > m ? e.id : m),
        0,
      );
      if (maxId > 0) this.nextId = maxId + 1;
      const prefsRes = await supabase
        .from("user_preferences")
        .select("theme_bg, theme_text, theme_surface")
        .eq("user_id", uid)
        .maybeSingle();
      if (prefsRes.data) {
        this.loadingThemeFromSupabase = true;
        if (prefsRes.data.theme_bg != null)
          this.themeBg = prefsRes.data.theme_bg;
        if (prefsRes.data.theme_text != null)
          this.themeText = prefsRes.data.theme_text;
        if (prefsRes.data.theme_surface != null)
          this.themeSurface = prefsRes.data.theme_surface;
        this.$nextTick(() => {
          this.loadingThemeFromSupabase = false;
        });
      }
    },
    async saveThemeToSupabase() {
      if (!supabase || !this.syncEnabled) return;
      const uid = (await supabase.auth.getUser()).data?.user?.id;
      if (!uid) return;
      await supabase.from("user_preferences").upsert(
        {
          user_id: uid,
          theme_bg: this.themeBg,
          theme_text: this.themeText,
          theme_surface: this.themeSurface,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "user_id" },
      );
    },
    async addExpenseToSupabase(expense) {
      if (!supabase || !this.syncEnabled)
        return { id: expense.id, error: null };
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
      const { error } = await supabase
        .from("categories")
        .insert({ user_id: uid, name });
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
    resetTheme() {
      this.themeBg = "#f3f4f6";
      this.themeText = "#111827";
      this.themeSurface = "#ffffff";
    },
    debouncedSaveTheme() {
      if (this.themeSaveTimeout) clearTimeout(this.themeSaveTimeout);
      this.themeSaveTimeout = setTimeout(() => {
        this.themeSaveTimeout = null;
        this.saveThemeToSupabase();
        this.themeSaveMessage = "Saved";
        setTimeout(() => (this.themeSaveMessage = ""), 2000);
      }, 1000);
    },
  },
};
</script>

<template>
  <div
    class="min-h-screen transition-colors"
    :style="{
      backgroundColor: themeBg,
      color: themeText,
      '--theme-surface': themeSurface,
      '--theme-text': themeText,
    }"
  >
    <!-- Header with hamburger -->
    <header
      class="border-b border-black sticky top-0 z-20 flex items-center justify-between px-4 py-3"
      :style="{ backgroundColor: themeSurface }"
    >
      <button
        @click="toggleMenu"
        class="p-2 border border-black rounded hover:opacity-80"
        aria-label="Toggle menu"
        :style="{ backgroundColor: themeSurface, color: themeText }"
      >
        <span
          class="block w-6 h-0.5 mb-1"
          :style="{ backgroundColor: themeText }"
        ></span>
        <span
          class="block w-6 h-0.5 mb-1"
          :style="{ backgroundColor: themeText }"
        ></span>
        <span
          class="block w-6 h-0.5"
          :style="{ backgroundColor: themeText }"
        ></span>
      </button>
      <h1 class="text-lg font-bold">Expense Tracker</h1>
      <div class="flex items-center gap-2">
        <span v-if="syncLoading" class="text-xs opacity-70">...</span>
        <span
          v-else-if="syncEnabled"
          class="text-xs font-medium text-green-600"
          title="Synced to cloud"
          >Synced</span
        >
        <template v-if="isSupabaseConfigured()">
          <button
            v-if="userIsAnonymous"
            @click="openAuth"
            class="text-sm font-medium px-3 py-1.5 rounded border border-black hover:opacity-80"
            :style="{ backgroundColor: themeSurface, color: themeText }"
          >
            Sign in
          </button>
          <button
            v-else
            @click="signOut"
            class="text-sm font-medium text-red-600 px-3 py-1.5 rounded border border-red-500 hover:opacity-80"
            :style="{ backgroundColor: themeSurface }"
          >
            Sign out
          </button>
        </template>
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
        'fixed top-0 left-0 z-40 h-full w-56 border-r border-black shadow-lg transition-transform duration-200',
        menuOpen ? 'translate-x-0' : '-translate-x-full',
      ]"
      :style="{ backgroundColor: themeSurface }"
    >
      <div class="p-4 border-b border-black font-bold">Menu</div>
      <button
        @click="setSection('expenses')"
        class="w-full text-left px-4 py-3 border-b border-black hover:opacity-80"
        :style="{ backgroundColor: themeSurface, color: themeText }"
      >
        Expenses
      </button>
      <button
        @click="setSection('categories')"
        class="w-full text-left px-4 py-3 border-b border-black hover:opacity-80"
        :style="{ backgroundColor: themeSurface, color: themeText }"
      >
        Categories
      </button>
      <button
        @click="setSection('history')"
        class="w-full text-left px-4 py-3 border-b border-black hover:opacity-80"
        :style="{ backgroundColor: themeSurface, color: themeText }"
      >
        History
      </button>
      <button
        @click="setSection('theme')"
        class="w-full text-left px-4 py-3 border-b border-black hover:opacity-80"
        :style="{ backgroundColor: themeSurface, color: themeText }"
      >
        Theme
      </button>
    </nav>

    <!-- Auth modal (always default theme) -->
    <div
      v-if="showAuthScreen"
      class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50"
      @click.self="closeAuth"
    >
      <div
        class="rounded-lg border border-black shadow-xl max-w-sm w-full p-6 bg-white text-gray-900"
        @click.stop
      >
        <h2 class="text-xl font-bold mb-2">
          {{ authMode === "signup" ? "Create account" : "Sign in" }}
        </h2>
        <p class="text-sm text-gray-600 mb-4">Sync your data across devices</p>
        <div v-if="authLoading" class="py-8 text-center text-gray-600">
          <div class="inline-block w-8 h-8 border-2 border-gray-400 border-t-blue-500 rounded-full animate-spin mb-3"></div>
          <p class="font-medium">Signing in...</p>
        </div>
        <div v-else class="space-y-4">
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
          v-if="authMessage && !authLoading"
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

    <!-- Post sign-in loading -->
    <div
      v-if="postAuthLoading"
      class="fixed inset-0 z-40 flex items-center justify-center bg-white/90"
    >
      <div class="text-center">
        <div class="inline-block w-10 h-10 border-2 border-gray-300 border-t-green-600 rounded-full animate-spin mb-4"></div>
        <p class="text-lg font-medium text-gray-800">Loading your data...</p>
      </div>
    </div>

    <!-- Success message -->
    <div
      v-if="authSuccessMessage"
      :class="[
        'mx-4 mt-4 p-3 text-white rounded flex items-center justify-between',
        authSuccessMessage === 'Signed out.' ? 'bg-red-600' : 'bg-green-600',
      ]"
    >
      <span>{{ authSuccessMessage }}</span>
      <button
        @click="authSuccessMessage = ''"
        :class="authSuccessMessage === 'Signed out.' ? 'bg-red-800 px-2 py-1 rounded hover:bg-red-700' : 'bg-green-800 px-2 py-1 rounded hover:bg-green-700'"
      >
        ×
      </button>
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
              :style="{ backgroundColor: themeSurface, color: themeText }"
            />
          </div>
          <div class="flex-1">
            <label for="expense-category" class="block text-sm font-medium mb-1"
              >Category</label
            >
            <select
              id="expense-category"
              v-model="selectedCategory"
              class="w-full p-2 border border-black rounded"
              :style="{ backgroundColor: themeSurface, color: themeText }"
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
        <p v-if="categories.length === 0" class="text-sm opacity-80">
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
            :style="{ backgroundColor: themeSurface, color: themeText }"
            @keyup.enter="addCategory"
          />
          <button
            @click="addCategory"
            class="px-4 py-2 bg-blue-500 text-white font-medium rounded border border-black hover:bg-blue-600"
          >
            Add
          </button>
        </div>
        <ul class="border border-black rounded divide-y divide-black overflow-hidden">
          <li
            v-for="cat in categories"
            :key="cat"
            class="flex items-center justify-between p-2"
            :style="{ backgroundColor: themeSurface, color: themeText }"
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
        <p v-if="categories.length === 0" class="text-sm opacity-80">
          No categories yet. Add one above.
        </p>
      </section>

      <!-- History section -->
      <section v-show="currentSection === 'history'" class="space-y-4">
        <h2 class="text-xl font-bold border-b border-black pb-2">History</h2>
        <ExpensePieChart :expenses="filteredHistory" :text-color="themeText" />
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
                timeFilter === opt.value ? 'bg-black text-white' : 'hover:opacity-90',
              ]"
              :style="timeFilter !== opt.value ? { backgroundColor: themeSurface, color: themeText } : {}"
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
                historyFilter === 'all' ? 'bg-black text-white' : 'hover:opacity-90',
              ]"
              :style="historyFilter !== 'all' ? { backgroundColor: themeSurface, color: themeText } : {}"
            >
              All
            </button>
            <button
              v-for="cat in categoriesForFilter"
              :key="'filter-' + cat"
              @click="historyFilter = cat"
              :class="[
                'px-3 py-1 rounded border border-black text-sm font-medium',
                historyFilter === cat ? 'bg-black text-white' : 'hover:opacity-90',
              ]"
              :style="historyFilter !== cat ? { backgroundColor: themeSurface, color: themeText } : {}"
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
            class="flex items-center justify-between p-3"
            :style="{ backgroundColor: themeSurface, color: themeText }"
          >
            <div>
              <span class="font-bold">${{ entry.amount.toFixed(2) }}</span>
              <span class="ml-2 opacity-90">{{ entry.category }}</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="text-sm opacity-75">{{ entry.date }}</span>
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

      <!-- Theme section -->
      <section v-show="currentSection === 'theme'" class="space-y-4">
        <div
          class="flex items-center justify-between border-b border-black pb-2"
        >
          <h2 class="text-xl font-bold">Theme</h2>
          <div class="flex items-center gap-2">
            <button
              @click="resetTheme"
              class="text-sm font-medium px-3 py-1.5 rounded border border-black hover:opacity-80 bg-white text-gray-900"
            >
              Reset
            </button>
          </div>
        </div>
        <p class="text-sm opacity-80">
          {{ themeSaveMessage || "Changes save automatically when you're signed in." }}
        </p>
        <div
          class="space-y-4 border border-black rounded p-4"
          :style="{ backgroundColor: themeSurface }"
        >
          <div class="flex flex-wrap items-center gap-3">
            <label class="text-sm font-medium w-28">Background</label>
            <input
              v-model="themeBg"
              type="color"
              class="w-12 h-12 rounded border-2 border-black cursor-pointer"
              title="Background color"
            />
            <span class="text-sm">{{ themeBg }}</span>
          </div>
          <div class="flex flex-wrap items-center gap-3">
            <label class="text-sm font-medium w-28">Text color</label>
            <input
              v-model="themeText"
              type="color"
              class="w-12 h-12 rounded border-2 border-black cursor-pointer"
              title="Text color"
            />
            <span class="text-sm">{{ themeText }}</span>
          </div>
          <div class="flex flex-wrap items-center gap-3">
            <label class="text-sm font-medium w-28">Cards & panels</label>
            <input
              v-model="themeSurface"
              type="color"
              class="w-12 h-12 rounded border-2 border-black cursor-pointer"
              title="Surface color (header, menu, cards)"
            />
            <span class="text-sm">{{ themeSurface }}</span>
          </div>
        </div>
      </section>
    </main>
  </div>
</template>

<style scoped>
/* Force theme on inputs/selects so text and background follow theme */
input,
select {
  background-color: var(--theme-surface) !important;
  color: var(--theme-text) !important;
}
input::placeholder {
  color: var(--theme-text);
  opacity: 0.7;
}
</style>
