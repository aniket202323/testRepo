Create Procedure dbo.spEC_LoadIconIds
 AS
Select Icon_Id From Icons Where Icon is not null
