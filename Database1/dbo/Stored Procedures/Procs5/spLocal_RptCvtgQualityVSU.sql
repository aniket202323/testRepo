  
/************************************************************************  
  
Author:  Steven Stier, Stier-Automation, LLC  
Last Update: 2009-06-01 Rev1.00  
  
Update History:  
  
2009-06-01 Steven Stier -  RollOut  
2009-06-22 Steven Stier -  Changed to show all product when @ReturnINProductGroup = 0  
2009-10-20  Langdon Davis - Modified population of @ProductGrpIdList when @ReturnINProductGroup = 0 to   
          avoid duplication of data.  
  
------------------------------------------------------------------------------------------------------------  
-- SP sections:  [Note that additional comments can be found in each section.]  
------------------------------------------------------------------------------------------------------------  
  
Section 1:  Declare testing parameters.  
Section 2:  Declare variables  
Section 3:  Declare the table variables for the data  
Section 4:  Get the Inputs required for the Function Call  
Section 5:  call the Other SP  
*************************************************************************/  
  
CREATE PROCEDURE [dbo].[spLocal_RptCvtgQualityVSU]  
--declare  
 @LangID int,  
 @pStartDate  DATETIME,  
 @pEndDate  DATETIME,  
 @Line  varchar(100),  
 @ProductGroupList varchar(4000),  -- Collection of ProductGroups for converting lines delimited by "|".  
 @ReturnINProductGroup varchar(50) -- Should i return the data for only the times when the line ran a qualified product  
  
AS  
-------------------------------------------------------------------------------  
-- Control settings  
-------------------------------------------------------------------------------  
SET ANSI_WARNINGS OFF  
SET NOCOUNT ON  
  
-------------------------------------------------------------------------------  
-- Section 1: Declare testing parameters.  
-------------------------------------------------------------------------------  
  
--Test  
  
/*SELECT   
 @LangID = 0,  
 @pStartDate  = '2009-05-01 00:00:00',  
 @Line = 'TT GT01',  
 --@ProductGroupList = 'All',  -- Collection of ProductGroups for converting lines delimited by "|".  
 --@ProductGroupList = 'CH Ultra Lexus 1-0 Reg Roll',  
 @ProductGroupList = 'CH Ultra Lexus 1-0 Mega Roll',  
 --@ProductGroupList = 'CH Ultra Lexus 1-0 Reg Roll|CH Ultra Lexus 1-0 Big Roll',   
 --@ProductGroupList = 'xx',  
 @ReturnINProductGroup = '1'  
  
*/  
  
-- exec spLocal_RptCvtgQualityVSU 1,'2009-05-01 00:00:00','TT GT01','CH Ultra Lexus 1-0 Mega Roll','1'  
  
--------------------------------------------------------  
-- Section 2: Declare variables  
--------------------------------------------------------  
  
Declare @LineStatusList varchar(7000)  
Declare @PLId varchar(1000)  
Declare @ProductGrpIdList varchar(7000)  
declare @EndDate DATETIME  
  
----------------------------------------------------------------------------------  
-- Section 3: Declare table variables for the data  
----------------------------------------------------------------------------------  
  
declare @ProductGroups table  
(  
 Product_grp_ID     int,  
 Product_grp_Desc    varchar(50)  
 )  
-----------------------------------------------------------------------------------  
-- Section 4: Get the Inputs required for the PPM Subroutine Call  
  
-----------------------------------------------------------------------------------  
-----------------------------------------------------------------------------------  
---- Line Status List  
-----------------------------------------------------------------------------------  
Select @LineStatusList = ''  
Select @LineStatusList = @LineStatusList + + convert(varchar,p.Phrase_ID)+'^'+p.Phrase_Value + ','  
 FROM Phrase p  
  where p.Data_Type_Id = (Select dt.Data_Type_ID from Data_type dt WHERE dt.Data_Type_Desc = 'Line Status')  
  and p.Phrase_Value like '%PR In:%'   
  
--Select '@LineStatusList=' + @LineStatusList  
  
-----------------------------------------------------------------------------------  
---- Production Line ID  
-----------------------------------------------------------------------------------    
Select @PLId  = (Select PL_ID from Prod_Lines where PL_Desc = @Line)  
-- TO DO should we check for valid Line ID  
  
--Select '@PLID=' + @PLID  
  
-----------------------------------------------------------------------------------  
---- Product Group ID List  
-----------------------------------------------------------------------------------  
-- If the data requested is the In the Product Group List selected than   
--  use that selection in the query else get all the other data  
--  
If @ReturnINProductGroup = '1'  
 BEGIN  
  
  Insert @ProductGroups (Product_grp_ID,Product_grp_Desc)  
  Select Product_grp_ID, Product_Grp_Desc_Global From Product_groups  
   WHERE ((External_Link) Like '%HiLevel=2%')   
    and ((External_Link) Not Like '%PmkgParentID%')  
    and (CHARINDEX('|' + Product_Grp_Desc_Global + '|','|' + @ProductGroupList + '|') > 0  
      OR  @ProductGroupList = 'All')  
 Select @ProductGrpIdList = ''  
 Select @ProductGrpIdList = @ProductGrpIdList + + convert(varchar,Product_grp_ID)+'|'  
 FROM @ProductGroups  
 END  
ELSE  
 BEGIN  
  Insert @ProductGroups (Product_grp_ID,Product_grp_Desc)  
  Select Product_grp_ID, Product_Grp_Desc_Global From Product_groups  
   WHERE ((External_Link) Like '%HiLevel=1%')   
 Select @ProductGrpIdList = ''  
 Select @ProductGrpIdList = @ProductGrpIdList + + convert(varchar,Product_grp_ID)+'|'  
 FROM @ProductGroups  
 END  
  
  
  
--select '@ProductGrpIdList=' + @ProductGrpIdList  
  
  
  
  
  
-------------------------------------------------------------------------------------  
-- Call the PPM Calculation Routine  
-------------------------------------------------------------------------------------  
  
Exec dbo.spLocal_Rpt_NormPPM40_VSU '',@pStartDate,@pEndDate,'VASReport',@PLID,@ProductGrpIdList,@LineStatusList  
  
RETURN  
