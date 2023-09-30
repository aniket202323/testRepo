-------------------------------------------------------------------------------------------------  
  
/*  
Stored Procedure: dbo.spLocal_Parts_BAT_Tool  
Author:    John Yannone  
Date Created:  June 30, 2005  
Purpose:    When within the PARTS app, a user deletes a Paper Type record, the deletion of the   
        PaperTypeName is to be carried over to Proficy, e.g, Product_Grp_desc(Paper Type Name)  
        must be deleted from Product_Groups table. However, we must first check in Proficy to   
      see before we can perform a delete, if there are products associated with this group   
      that are still being run(we do this by querying the PRODUCTION_STARTS table).  If   
      entries are found in this table then there are still products running that are associated   
        with a Product Group and so we can not perform the deletion. This proc performs these checks   
        and notifies the PARTS app if it ok to go ahead and delete or cancel the deletion.  
            
      RetVal = 0  returned to the app means no actively running products associated with this   
                      Product_Grp_Desc   
          RetVal = 1  returned to the app means that there is currently at least one product running   
                      with an association to the Product_Grp_Desc.  
     
      This SP is called from within PARTS:   
          -----   CProficyCustom (class module)      ------  
          -----   QuerySqlServer (Public Sub Procedure)   -----  
      
CHANGE HISTORY:  
==============  
03-FEB-2008 Langdon Davis  
 -- When paper types get deleted in PARTS, the PARTS application does not delete them from Proficy if there are   
  any production starts for products in the product group associated with with that paper type.  To delete or   
  not to delete is managed via a call to the spLocal_Parts_ProductGrpDescDeletionCk sp.  If a paper type can   
  be deleted from PARTS, the corresponding product group can and should be deleted from Proficy.  Long term   
  answer to fixing this is to remove the call to above sp from the PARTS and delete the sp from the Proficy   
  database.  Short term, is comment out "all" the code in this sp and just return a 0 value to PARTS.   
  
*/  
  
CREATE    PROCEDURE spLocal_Parts_ProductGrpDescDeletionCk  
  
@RetVal             int OUTPUT,  
@PaperTypeName      varchar(50)      
  
AS DECLARE  
@product_id        int,  
@prod_id           int,  
@cursor_state      int,  
@product_grp_id    int  
  
BEGIN   
  
--Initialize the return variable.  
SELECT @RetVal = 0  
  
/* If we are deleting a paper type in PARTS, we ALWAYS want to perform the corresponding product group  
 deletion in Proficy.  We cannot delete a product group within PARTS if there are any brand codes  
 that are still using it.  Therefore, it makes no sense to not delete it within Proficy if it is able  
 to be deleted within PARTS.  Long term answer is to remove the call to this sp from the PARTS   
 application.  Short term, we will simply comment out all the code below and just return a 0 value  
 to PARTS.   FLD 03-FEB-2008   
  
--Initialize cursor state  
SELECT @cursor_state = 0  
     
    IF (SELECT COUNT(*)  
        FROM   PRODUCT_GROUPS  
        WHERE  Product_Grp_desc_Global = @PaperTypeName) > 0  
  
        begin          
            SELECT @product_grp_id = product_grp_id  
            FROM   PRODUCT_GROUPS   
            WHERE  Product_Grp_desc_Global = @PaperTypeName  
  
            --There may be more than one prod_id associated with  
            --this Product_Grp_Id.  
            IF (SELECT count(*)  
                FROM PRODUCT_GROUP_DATA  
                WHERE Product_Grp_Id = @product_grp_id) > 1  
   
                    --If so declare a cursor to retrieve them all and  
                    --then loop through the cursor until at least one   
                    --of the values returns true.  
                    begin  
                      DECLARE CurGetProdIds Cursor for  
                      SELECT prod_id   
                      FROM PRODUCT_GROUP_DATA  
                      WHERE Product_Grp_Id = @product_grp_id   
  
                      OPEN  CurGetProdIds  
                      FETCH NEXT FROM CurGetProdIds INTO @prod_id  
                      WHILE (@@FETCH_STATUS <> -1)  
                           
                          --If we do have an entry in the PRODUCTION_STARTS  
                          --table then send the msg back to the calling app  
                          --that the records cannot be deleted.  
                           begin   
  
                              --Set cursor state = 1 to signify that it has been opened.  
    SELECT @cursor_state = 1  
  
                             IF (SELECT count(*)  
                          FROM PRODUCTION_STARTS  
                          WHERE Prod_Id = @prod_id) > 0  
                        begin  
                          select @RetVal = 1  
                                     IF @cursor_state = 1  
                                        begin  
                                           close CurGetProdIds  
                                           deallocate CurGetProdIds  
                                        end  
                          RETURN   
                               end  
                     ELSE  
                               begin  
                                select @RetVal = 0  
                                FETCH NEXT FROM CurGetProdIds INTO @prod_id   
                               end  
                           end  
  
                  end   
          ELSE  -- Theres only one prod_id needed to query the   
                          -- production starts table.  
                     begin  
                        SELECT @prod_id = Prod_Id  
                 FROM PRODUCT_GROUP_DATA  
                 WHERE Product_Grp_Id = @product_grp_id  
   
                 IF (SELECT count(*)  
                     FROM PRODUCTION_STARTS  
                     WHERE Prod_Id = @prod_id) > 0  
   
                       select @RetVal = 1  
  
                  ELSE  
  
                       select @RetVal = 0  
  
                     end  
               end  
ELSE  
    begin  
       select @RetVal = 0                   
    end  
END  
  
IF @cursor_state = 1  
 begin  
    close CurGetProdIds  
    deallocate CurGetProdIds  
 end  
  
*/  --FLD 03-FEB-2008  
END --FLD 03-FEB-2008  
  
RETURN   
  
  
  
