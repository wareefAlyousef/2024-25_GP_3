# 2024-25_GP_28

## Introduction

Managing insulin dosages for individuals with Type 1 diabetes is a complex and high-stakes task due ‎to the constant need to adjust for daily fluctuations in diet, exercise, and blood glucose levels. With ‎the pancreas unable to produce insulin, external insulin administration becomes essential for ‎survival. However, maintaining healthy blood sugar levels is challenging, as they are influenced by ‎dynamic factors such as carbohydrate intake, physical activity, stress, illness, and sleep ‎[19]. This ‎variability makes precise insulin dosing difficult.‎

For example, consuming a high-carbohydrate meal can cause blood glucose levels to spike, ‎requiring a larger insulin dose, while exercise typically lowers blood glucose, necessitating a ‎reduction in insulin or additional carbohydrate intake to prevent hypoglycemia. A person with Type 1 ‎diabetes may need to balance these opposing effects daily. Misjudging insulin needs can lead to dangerous consequences—too much ‎insulin may cause hypoglycemia during or after exercise, while too little insulin can result in ‎hyperglycemia, leading to serious health risks. Chronic hyperglycemia increases ‎the likelihood of long-term complications such as cardiovascular disease, kidney failure, and nerve ‎damage. Acute hypoglycemia can trigger symptoms like dizziness, confusion, seizures, ‎unconsciousness, or even death if not treated promptly [20], [21], [22]. This constant balancing act requires ‎vigilance, flexibility, and real-time decision-making, often relying on personal intuition, which is not ‎always reliable.‎

To address these challenges, “InsulinSync” provides real-time insulin dosage ‎recommendations by integrating data inputs from food intake, exercise, and current glucose ‎readings. By offering tailored guidance based on real-time data, “InsulinSync” aims to minimize the ‎risks associated with improper insulin management and empower users with safer, more effective ‎diabetes control, ultimately enhancing their quality of life.‎ 

### The Solution
To address the problem, we propose developing an application “InsulinSync” to help people with Type 1 diabetes to manage their insulin dosage and maintain normal blood glucose level.

The application features an optimization algorithm that pulls real-time glucose data from a continuous glucose monitor, collects exercise information directly from the user or by synchronizing it with fitness applications and collects nutritional data in consumed meals. The application will provide users with multiple options to input their meal’s nutritional data and carbohydrates content, including scanning food item barcodes to automatically get the nutritional details, searching for the meal by its name and manually entering the amount in grams and it will feature a tool that analyses images of meals to estimate their carbohydrate content, allowing the user to simply upload or take a picture of their meals. Before processing, the user verifies all the data. The verified information is then fed into the optimization algorithm, which calculates the recommended insulin dosage.

“InsulinSync” application will provide a set of essential functionalities, including the 
following key features:
•	Personalized recommended insulin dosage calculation after entering the meal taking into account the user’s glucose level, the amount of carbohydrates in the meal and the physical activity and it takes the users verification before processing the information.
•	Connecting the application to a continuous glucose monitor to provide real-time glucose data and allow continuously tracking the glucose levels.
•	Integrating with health related applications to track the users’ exercises and gather information about their physical activity level. 
•	Image-based carbohydrate analysis model that can estimate the amount of carbohydrate in meals based on images that are taken by the user.
•	Barcode scanning for food products to retrieve their nutritional information particularly the amount of carbohydrates.
•	Visualizing the user’s glucose levels, insulin dosages, physical activity and meals data to easily track and manage health information.

The solution will help improve diabetes management by simplifying the process of calculating the right amount of insulin dosage and reducing the risk of human calculation errors leading to better health status.

## Technology  
Dart 
python

## Launching instructions
In this stage of develpment there are no launching instructions yet.
