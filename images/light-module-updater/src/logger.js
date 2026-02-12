const BLUE = '\x1b[1;34m';
const RED = '\x1b[1;31m';
const ORANGE = '\x1b[1;33m';
const BOLD = '\x1b[1m';
const NC = '\x1b[0m';

export function bold(text) {
  return `${BOLD}${text}${NC}`;
}

export const logger = {
  info(message) {
    console.log(`[${BLUE}INFO${NC}] ${message}`);
  },

  error(message) {
    console.log(`[${RED}ERROR${NC}] ${message}`);
  },

  warn(message) {
    console.log(`[${ORANGE}WARN${NC}] ${message}`);
  },
};
