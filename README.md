# Quests
this is the code for all the quest on https://www.questbook.app/.

# Track1-Quest1

A simple bank on the ethereum blockchain that allows for deposit of eth and gives simple interest on withdrawal.

# Track1-Quest2
Contract for a simple bank that accrues real interest through Compund, allows deposit from users and then moves fund to compound where it earns interests.

# Track1-Quest3
smart contract allows for the deposit of all types of crypto currencies(ERC20 compliant), and then moves them to compound in eth behind the doors,
accrues interest and allows the user to withdraw back either in eth or any currency.

# Track1-Quest4
Smart contract for Launching an Erc20 token, which can be mined every 10th ethereum blocks on a first come first served basis(first user to hit the mine butto,
i know it's no proof of work, but it's good for now :) )

# Track2-Quest1
Built a Smart Token using bancor curve as it's liquidity formula, what this means is that this token does not need to be listed on uniswap yet, the contract provides a trustworthy and stable(if a reasonable reserve ratio is used) price for buying and selling the token at any time.this liquidity depends largely on the state of the tokens circulating supply and its reserve balance(eth balance in this case). the Bancor formula was shamelessly adapted from the Bancor Protocol github page, struggled with the math.  10% reserve ratio would see a very aggressiv erise in price as the token supply increases, making it perhaps unsustainable? a 50% reserve ratio brings a more stable rise as the token supply increase, while a 100% reserve ratio would perhaps make our token a stable coin.