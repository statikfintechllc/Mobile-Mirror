/** @type {import('ts-jest').JestConfigWithTsJest} **/
module.exports = {
    projects: ['<rootDir>/language-server/jest.config.js', '<rootDir>'],
    collectCoverageFrom: ['src/**/*.{js,jsx,ts,tsx}', '!src/**/*.test.{js,jsx,ts,tsx}', '!src/test/**/*.*'],
    testEnvironment: 'node',
    testMatch: ['<rootDir>/src/test/unit/**/*.test.{ts,js,jsx,tsx}'],
    collectCoverage: true,
    coverageReporters: ['json-summary', 'json', 'lcov', 'text'],
    modulePathIgnorePatterns: ['<rootDir>/dist/', '.*/node-modules/', '<rootDir>/.vscode-test/'],
    transform: {
        '^.+\.tsx?$': [
            'ts-jest',
            {
                tsconfig: 'tsconfig.test.json'
            }
        ]
    }
};
