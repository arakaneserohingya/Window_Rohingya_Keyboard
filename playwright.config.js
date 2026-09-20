const {defineConfig} = require('@playwright/test');
module.exports = defineConfig({testDir:'tests/browser',use:{headless:true,launchOptions:process.env.BROWSER_EXECUTABLE ? {executablePath:process.env.BROWSER_EXECUTABLE} : {}},reporter:'list'});
