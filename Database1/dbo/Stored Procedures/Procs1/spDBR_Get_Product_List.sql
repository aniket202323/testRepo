Create Procedure dbo.spDBR_Get_Product_List
@pgid int,
@punitID int = NULL,
@startTime datetime = NULL,
@endTime datetime = NULL 
as
 	 if (@pgid=-3)
 	 begin
 	  	 select prod_id, prod_desc, prod_code from products where prod_id > 1 order by prod_desc
 	 end
 	 else if (@pgid = -2)
 	 begin
 	     If @endTime < @startTime Select @endTime = dbo.fnServer_CmnGetDate(getutcdate())
 	  	 If (@punitID = -1) -- @punitID is null
 	  	 begin
 	  	  	 select distinct p.prod_id, p.prod_Desc, p.prod_code from products p, production_starts ps 
 	  	  	 where p.prod_id > 0 and p.prod_id = ps.prod_id and p.prod_id > 1 and 
 	  	  	  	  ((ps.Start_Time <= @startTime AND ps.End_Time IS Null) OR
 	  	  	  	   (ps.Start_Time <= @startTime AND ps.End_Time > @startTime) OR
 	  	  	  	   (ps.Start_Time > @startTime AND ps.End_Time < @endTime) OR
 	  	  	  	   (ps.Start_Time > @startTime AND ps.Start_Time < @endTime)) 	 
 	  	  	 order by p.prod_desc
 	  	 end
 	  	 else -- @punitID is not null
 	  	 begin
 	  	  	 select distinct p.prod_id, p.prod_Desc, p.prod_code from products p, production_starts ps 
 	  	  	 where p.prod_id > 0 and p.prod_id = ps.prod_id and p.prod_id > 1 and ps.pu_id = @punitID and
 	  	  	  	  ((ps.Start_Time <= @startTime AND ps.End_Time IS Null) OR
 	  	  	  	   (ps.Start_Time <= @startTime AND ps.End_Time > @startTime) OR
 	  	  	  	   (ps.Start_Time > @startTime AND ps.End_Time < @endTime) OR
 	  	  	  	   (ps.Start_Time > @startTime AND ps.Start_Time < @endTime)) 	 
 	  	  	 order by p.prod_desc
 	  	 end
 	 end
 	 else if(@pgid = -1)
 	 begin
 	  	 select -1 as prod_id, '[any product]' as prod_desc, '[any product]' as prod_code
 	 end
 	 else
 	 begin
 	  	 select p.prod_id, p.prod_desc, p.prod_code from products p, product_Group_data pg where p.prod_id > 0 and pg.product_grp_id = @pgid and p.prod_id = pg.prod_id
 	 end
