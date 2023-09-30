create PROCEDURE multipleData  
   @Id int    
     
AS    
BEGIN    

 select top 1 * from Local_PG_eCIL_Routes 
 select top 1 * from Local_PG_eCIL_TeamUsers 
 
END