      CREATE    PROCEDURE spLocal_Parts_ProductGrpDescUpdate  
  
--Author: John Yannone July 27, 2005.  
  
/* When within the PARTS app, a user updates the Paper Type Name in a   
   Paper Type record, the update of the PaperTypeName is to be carried   
   over to Proficy to update the Product_Grp_Desc in the Product_Groups table.   
   This SP is called from within PARTS:   
    -----   CProficyCustom (class module)   ------  
    -----   UpdateProfProductGrpDesc (Public Sub Procedure) -----  
   Special Note: This SP is not yet tested for 4.x compliance, although references to   
                 Global Desc have been made where appropriate.   */   
  
@RetVal             int OUTPUT,  
@errcode            int OUTPUT,  
@errdesc            varchar(255) OUTPUT,  
@NewPaperTypeName   varchar(50),  
@OldPaperTypeName   varchar(50)      
  
AS DECLARE  
@err_id  int  
  
BEGIN   
  
--Initialize the error handling variables.  
SELECT @errcode = 0  
SELECT @errdesc = ''  
  
            BEGIN tran  
  
            UPDATE Product_Groups  
            SET Product_Grp_Desc_Global = @NewPaperTypeName,  
                Product_Grp_Desc_Local = @NewPaperTypeName  
            WHERE Product_Grp_Desc_Global = @OldPaperTypeName             
  
            SELECT @err_id = @@error  
            IF @err_id <> 0 GOTO error_handle  
  
            COMMIT tran  
            SELECT @RetVal = 0  
            RETURN   
  
END  
  
--System error handler.  
error_handle:  
SELECT @errcode = @err_id  
  
SELECT @errdesc = description     
FROM   master.dbo.sysmessages  
WHERE  error = @err_id  
  
ROLLBACK tran  
SELECT @RetVal = 1  
RETURN  
  
  
  
  
  
  
