   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-09  
Version  : 1.0.2  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_SetSpeed  
Author:   Matthew Wells (MSI)  
Date Created:  08/01/01  
  
Description:  
=========  
Sets the speed-based product on the destination units by choosing the speed product FROM the Characteristic Group.  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
07/16/03 MKW Updated for 215.508  
*/  
  
CREATE procedure dbo.spLocal_SetSpeed  
@Output_Value varchar(25) OUTPUT,  
@Source_PU_Id int,  
@Start_Time datetime,  
@Prop_Desc varchar(25),  
@Speed varchar(25),  
@Destination_PU_Id1 int,  
@Destination_PU_Id2 int,  
@Destination_PU_Id3 int,  
@Destination_PU_Id4 int,  
@Destination_PU_Id5 int,  
@Destination_PU_Id6 int,  
@Destination_PU_Id7 int,  
@Destination_PU_Id8 int,  
@Destination_PU_Id9 int  
AS  
  
SET NOCOUNT ON  
  
DECLARE @Prod_Id  int,  
 @Prod_Code   varchar(25),  
 @Prop_Id  int,  
 @Char_Group_Id int,  
 @Char_Desc  varchar(25),  
 @Speed_Prod_Id int,  
 @StrSQL    varchar(8000),  
 @AppVersion   varchar(30)  
   
  
-- Get the Proficy database version  
SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
/* Initialize */  
SELECT  @Speed  = '%' + rtrim(ltrim(str(convert(float, @Speed), 10, 0))),  
 @Start_Time = dateadd(s, 1, @Start_Time)  
  
/* Get the current product */  
SELECT @Prod_Code = Products.Prod_Code  
FROM [dbo].Production_Starts  
     INNER JOIN [dbo].Products ON Production_Starts.Prod_Id = Products.Prod_Id  
WHERE PU_ID = @Source_PU_Id  
 AND Start_Time = @Start_Time  
  
/* Get speed-based product through the characteristic groups */  
SELECT @Prop_Id = Prop_Id  
FROM [dbo].Product_Properties  
WHERE Prop_Desc LIKE rtrim(ltrim(@Prop_Desc))  
  
SELECT @Char_Group_Id = Characteristic_Grp_Id  
FROM [dbo].Characteristic_Groups  
WHERE Prop_Id = @Prop_Id  
 AND Characteristic_Grp_Desc LIKE @Prod_Code  
  
SELECT  @Char_Desc = Char_Desc  
FROM [dbo].Characteristics AS Chrs  
     INNER JOIN [dbo].Characteristic_Group_Data AS Grp ON Chrs.Char_Id = Grp.Char_Id   
WHERE Grp.Characteristic_Grp_Id = @Char_Group_ID  
 AND Chrs.Char_Desc LIKE @Speed  
  
SELECT @Speed_Prod_Id = Products.Prod_Id  
FROM [dbo].PU_Products  
     INNER JOIN [dbo].Products ON PU_Products.Prod_Id = Products.Prod_Id  
WHERE PU_Products.PU_Id = @Destination_PU_Id1  
 AND Products.Prod_Code LIKE @Char_Desc  
  
IF @Char_Desc IS NOT NULL  
     BEGIN  
     IF @Destination_PU_Id1 > 0  
          SELECT @StrSQL = 'SELECT 3, NULL, ' + convert(varchar(25), @Destination_PU_Id1) + ', ' + convert(varchar(25), @Speed_Prod_Id) +', ''' + convert(varchar(25), @Start_Time,120) + ''', 0'  
     IF @Destination_PU_Id2 > 0  
          SELECT @StrSQL = 'SELECT 3, NULL, ' + convert(varchar(25), @Destination_PU_Id2) + ', ' + convert(varchar(25), @Speed_Prod_Id) +', ''' + convert(varchar(25), @Start_Time,120) + ''', 0'  
     IF @Destination_PU_Id3 > 0  
          SELECT @StrSQL = 'SELECT 3, NULL, ' + convert(varchar(25), @Destination_PU_Id3) + ', ' + convert(varchar(25), @Speed_Prod_Id) +', ''' + convert(varchar(25), @Start_Time,120) + ''', 0'  
     IF @Destination_PU_Id4 > 0  
          SELECT @StrSQL = 'SELECT 3, NULL, ' + convert(varchar(25), @Destination_PU_Id4) + ', ' + convert(varchar(25), @Speed_Prod_Id) +', ''' + convert(varchar(25), @Start_Time,120) + ''', 0'  
     IF @Destination_PU_Id5 > 0  
          SELECT @StrSQL = 'SELECT 3, NULL, ' + convert(varchar(25), @Destination_PU_Id5) + ', ' + convert(varchar(25), @Speed_Prod_Id) +', ''' + convert(varchar(25), @Start_Time,120) + ''', 0'  
   IF @Destination_PU_Id6 > 0  
          SELECT @StrSQL = 'SELECT 3, NULL, ' + convert(varchar(25), @Destination_PU_Id6) + ', ' + convert(varchar(25), @Speed_Prod_Id) +', ''' + convert(varchar(25), @Start_Time,120) + ''', 0'  
     IF @Destination_PU_Id7 > 0  
          SELECT @StrSQL = 'SELECT 3, NULL, ' + convert(varchar(25), @Destination_PU_Id7) + ', ' + convert(varchar(25), @Speed_Prod_Id) +', ''' + convert(varchar(25), @Start_Time,120) + ''', 0'  
     IF @Destination_PU_Id8 > 0  
          SELECT @StrSQL = 'SELECT 3, NULL, ' + convert(varchar(25), @Destination_PU_Id8) + ', ' + convert(varchar(25), @Speed_Prod_Id) +', ''' + convert(varchar(25), @Start_Time,120) + ''', 0'  
     IF @Destination_PU_Id9 > 0  
          SELECT @StrSQL = 'SELECT 3, NULL, ' + convert(varchar(25), @Destination_PU_Id9) + ', ' + convert(varchar(25), @Speed_Prod_Id) +', ''' + convert(varchar(25), @Start_Time,120) + ''', 0'  
  
  IF @AppVersion LIKE '4%'  
   BEGIN  
    SELECT @StrSQL = @StrSQL + ',NULL,NULL,NULL'  
   END  
  
  EXEC (@StrSQL)  
  
     SELECT @Output_Value = convert(varchar(25), @Char_Desc)  
     END  
ELSE  
     SELECT @Output_Value = 'Invalid Speed'  
  
SET NOCOUNT OFF  
  
