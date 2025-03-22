<script>
export default {
  data() {
    return {
      money: 0,
      months: 0,
      month_budg: 0,
    };
  },
  computed: {
    month_budg() {
      if (this.money > 0 && this.months > 0) {
        return (this.month_budg = this.money / this.months);
      } else {
        return (this.month_budg = 0);
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col items-center justify-center">
    <h1 class="text-lg font-bold">Monthly Budget Calculator</h1>
    <label class="bg-green-600 text-black p-1 m-2">Money</label>
    <input class="text-black" type="number" v-model="money" />
    <label class="bg-green-600 text-black p-1 m-2">Months</label>
    <input class="text-black" type="number" v-model="months" />

    <label>Monthly Budget</label>
    <p>${{ month_budg }}</p>
  </div>
</template>
