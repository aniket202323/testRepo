    /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-23  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_CleanupOldPendingTransactions  
Author:   Joe Nichols  
Date Created:  2/26/04  
  
Description:  
=========  
Deletes all pending transactions older than the date specified.  
  
Syntax example:  
  
Execute spLocal_CleanupOldPendingTransactions '1/26/04'  
  
Change Date Who What  
=========== ==== =====  
*/  
CREATE PROCEDURE dbo.spLocal_CleanupOldPendingTransactions  
@CutoffDate  datetime  
  
As  
SET NOCOUNT ON  
Declare   
@count varchar(50),  
@response varchar(50)  
  
DELETE   
FROM [dbo].Trans_Variables  
FROM [dbo].Trans_Variables tv   
    INNER JOIN [dbo].Transactions t ON tv.Trans_Id = t.Trans_Id   
WHERE t.Approved_On IS NULL AND (t.Trans_Create_Date < @CutoffDate)  
  
Delete  
FROM  [dbo].Trans_Properties  
FROM  [dbo].Trans_Properties tp   
 INNER JOIN [dbo].Transactions t ON tp.Trans_Id = t.Trans_Id  
WHERE     (t.Approved_On IS NULL)AND (t.Trans_Create_Date < @CutoffDate)  
  
Delete  
FROM  [dbo].Trans_Characteristics  
FROM  [dbo].Trans_Characteristics tc  
 INNER JOIN [dbo].Transactions t ON tc.Trans_Id = t.Trans_Id  
WHERE     (t.Approved_On IS NULL)AND (t.Trans_Create_Date < @CutoffDate)  
  
Delete  
FROM  [dbo].Trans_Products  
FROM  [dbo].Trans_Products tpr  
 INNER JOIN [dbo].Transactions t ON tpr.Trans_Id = t.Trans_Id  
WHERE     (t.Approved_On IS NULL)AND (t.Trans_Create_Date < @CutoffDate)  
  
Delete  
FROM  [dbo].Trans_Char_Links  
FROM  [dbo].Trans_Char_Links tcl  
 INNER JOIN [dbo].Transactions t ON tcl.Trans_Id = t.Trans_Id  
WHERE     (t.Approved_On IS NULL)AND (t.Trans_Create_Date < @CutoffDate)  
  
Select @count = count(*)   
From [dbo].Transactions t  
WHERE     (Approved_On IS NULL) AND (t.Trans_Create_Date < @CutoffDate)  
  
  
Delete  
From [dbo].Transactions  
FROM [dbo].Transactions t   
WHERE     (Approved_On IS NULL) AND (t.Trans_Create_Date < @CutoffDate)  
  
Select @response = @count + ' Pending Transactions were deleted.'  
  
Select @response  
  
SET NOCOUNT OFF  
