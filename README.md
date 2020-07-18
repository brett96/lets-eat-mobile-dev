# Let's Eat!

Official Repository for the Let's Eat! mobile app.  

## Google Play Link

https://play.google.com/store/apps/details?id=lets_eat.project

## About The App
This is an app for all those times you want to go out to eat, but you can't decide where. Maybe you're with friends and you each want something different and can't agree on a place. With Let's Eat!, the decision is taken care of for you and you can be on your way to delicious food in seconds! Simply tell the app what you're in the mood for, and the app will find the best restaurants around you, and suggest one that satisfies your preferences. You can also coordinate and chat with groups in real-time within the app!

  #### Privacy
- All data users provide to us is encrypted before being stored in our database.  The only information Google Auth gives us when you sign in with google is your gmail address and the public name linked to your gmail account.

- While location services are required to utilize most app features, none of your location data is ever logged anywhere or shared with anyone

- Any privacy concerns may be addressed to: bretttomita@gmail.com

## Development Updates
This project is currently only supported by one developer as a side project.  Updates will be sporatic

If you notice a serious issue, email the details to: bretttomita@gmail.com
### Current: 7/17/2020
New Features:
  - Accounts can be created using Google Auth's 'Sign In With Google'.  Choosing to sign in with Google will automatically create an account for you using your name and gmail address.  If you already created an account with your gmail address and choose sign in with Google, your Google credentials will be merged with your existing account.  Saved restaurants and friends will not be lost, however the user's unique identifier we use to manage users in groups will be changed meaning the user will have to be re-added to all groups.  This should not affect saved restaurants or friends.
  - Added an offline map that loads if no location data is obtained
  
  
Pending Features:
  - iOS Version using Flutter w/ existing codebase
  - Placing reservations in-app
  - Improving Group Voting features
  - Order delivery/pickup
  - Improve Account (Management) UI
  - Improve offline maps
  - Fix sign in with google merge issues on pre-existing accounts not made via google auth
  - Improve the 'About' page
  
### 6/9/2020
  - Added experimental 'Delivery' page.  Returns nearby restaurants that offer delivery
  - Added a 'Restaurant Info' page that returns additional detailed info about the restaurant along with up to 3 pictures

