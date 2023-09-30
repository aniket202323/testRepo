CREATE Procedure dbo.spGE_GetValidProducts
@PU_Id int,
@PUG_ID Int
AS
set nocount on
If @PUG_ID = -1 
  Select [Key] = pu.Prod_Id,[Icon] = '1',[Product Code] = Prod_Code,Description = Prod_Desc
   From PU_Products pu
   Join Products p On p.Prod_Id = pu.Prod_Id
   Where PU_Id = @PU_Id
   Order by Prod_Code
Else
  Select [Key] = pu.Prod_Id,[Icon] = '1',[Product Code] = Prod_Code,Description = Prod_Desc
   From PU_Products pu
   Join Products p On p.Prod_Id = pu.Prod_Id
   Join Product_Group_Data pug on pug.Prod_Id = p.Prod_Id and  pug.Product_Grp_Id = @PUG_ID
   Where PU_Id = @PU_Id
   Order by Prod_Code
select Prod_Id
  From Production_Starts
  Where Start_Time <= dbo.fnServer_CmnGetDate(GetUTCDate()) and End_time is Null and PU_Id = @PU_Id
set nocount off
