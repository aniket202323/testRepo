      CREATE   PROCEDURE spLocal_Parts_ProductGrpDescDeletion  
  
-- John Yannone July 8,2005.  
  
/* When within the PARTS app, a user deletes a Paper Type record, the deletion of the   
   PaperTypeName is to be carried over to Proficy. The process will first call the   
   spLocal_Parts_ProductGrpDescDeletionCk SP to test and see if it's ok to delete  
   the records. This test must pass on all servers based on business area of the   
   PaperType being deleted.  
     
   This SP is called from within PARTS:   
    -----   CProficyCustom (class module)   ------  
    -----   QuerySqlServer (Public Sub Procedure)   -----  
   Special Note: This SP is not yet tested for 4.x compliance, although references to   
                 Global Desc have been made where appropriate. */   
  
@errcode            int OUTPUT,  
@errdesc            varchar(255) OUTPUT,  
@PaperTypeName      varchar(50)      
  
AS DECLARE  
@product_id      int,  
@prod_id         int,  
@product_grp_id  int,  
@cursor_state    int,  
@err_id          int  
  
BEGIN   
  
--Initialize the error handling variables.  
SELECT @errcode = 0  
SELECT @errdesc = ''  
--Initialize cursor state  
SELECT @cursor_state = 0  
  
BEGIN tran  
  
            SELECT @product_grp_id = product_grp_id  
            FROM   PRODUCT_GROUPS   
            WHERE  Product_Grp_desc_Global = @PaperTypeName  
  
            --There may be more than one prod_id associated with  
            --this Product_Grp_Id.  
            IF (SELECT count(*)  
                FROM PRODUCT_GROUP_DATA  
                WHERE Product_Grp_Id = @product_grp_id) > 1  
   
                    --If so declare a cursor to retrieve them all and  
                    --then loop through the cursor until all the    
                    --child records have been deleted.  
                    begin  
                      DECLARE CurGetProdIdsForDeletion Cursor for  
                      SELECT prod_id   
                      FROM PRODUCT_GROUP_DATA  
                      WHERE Product_Grp_Id = @product_grp_id   
  
                      OPEN  CurGetProdIdsForDeletion  
                      FETCH NEXT FROM CurGetProdIdsForDeletion INTO @prod_id  
                      WHILE (@@FETCH_STATUS <> -1)                           
                            
                           begin   
  
                                --Set cursor state = 1 to signify that it has been opened.  
    SELECT @cursor_state = 1  
  
                                --Delete the multiple children.     
                                DELETE FROM dbo.Product_Group_Data  
                                WHERE Product_Grp_Id = @product_grp_id  
                                AND Prod_Id = @prod_id  
  
                                SELECT @err_id = @@error  
                                IF @err_id <> 0 GOTO error_handle  
  
                                FETCH NEXT FROM CurGetProdIdsForDeletion INTO @prod_id   
                           end   
  
                    end   
  
            ELSE  -- Theres only one record to delete.  
  
                     begin  
          
                        SELECT @prod_id = Prod_Id  
                 FROM PRODUCT_GROUP_DATA  
                 WHERE Product_Grp_Id = @product_grp_id  
  
                        --Delete children 1st.  
                 DELETE FROM dbo.Product_Group_Data  
                        WHERE Product_Grp_Id = @product_grp_id  
                        AND Prod_Id = @prod_id  
  
                        SELECT @err_id = @@error  
                        IF @err_id <> 0 GOTO error_handle  
  
                        --Then the parent.  
                        DELETE FROM dbo.Product_Groups  
                        FROM   PRODUCT_GROUPS   
                        WHERE  Product_Grp_desc_Global = @PaperTypeName  
  
                        SELECT @err_id = @@error  
                        IF @err_id <> 0 GOTO error_handle  
  
                     end  
                 
END  
  
  
   IF @cursor_state = 1  
  
        begin  
            --Here's where the parent gets deleted if the cursor  
            --was used to delete the children.  
      DELETE FROM dbo.Product_Groups   
      FROM   PRODUCT_GROUPS   
      WHERE  Product_Grp_desc_Global = @PaperTypeName  
   
      SELECT @err_id = @@error  
      IF @err_id <> 0 GOTO error_handle  
              
             IF @cursor_state = 1  
               begin  
                CLOSE CurGetProdIdsForDeletion  
                deallocate CurGetProdIdsForDeletion  
               end  
        end  
  
--If we made it this far we can commit the tran!  
COMMIT tran  
  
RETURN   
  
--System error handler.  
error_handle:  
SELECT @errcode = @err_id  
  
SELECT @errdesc = description     
FROM   master.dbo.sysmessages  
WHERE  error = @err_id  
  
ROLLBACK tran  
  
    IF @cursor_state = 1  
  
        begin  
            CLOSE CurGetProdIdsForDeletion  
            deallocate CurGetProdIdsForDeletion  
        end  
  
RETURN  
  
  
  
  
  
  
