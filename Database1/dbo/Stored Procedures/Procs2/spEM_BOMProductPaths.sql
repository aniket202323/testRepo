CREATE PROCEDURE dbo.spEM_BOMProductPaths
 	 @Read int,
 	 @Path varchar(8000),
 	 @Order nvarchar(80),
 	 @Formulation int,
 	 @pp int
AS
 	 if @Read=1 
 	 begin
 	  	 set @Path=replace(replace(replace(replace(replace(@Path,'[','[[]'),'_','[_]'),'%','[%]'),'*','%'),'?','_')
 	  	 select Path_Id,Path_Code from Prdexec_Paths where Path_Code like @Path
 	 end
 	 else if @Read=2
 	 begin
 	  	 declare @paths table (pkey int)
 	  	 while charindex(' ',@Path)>0
 	  	 begin
 	  	  	 while charindex(' ',@Path)=1 set @Path=substring(@Path,2,8000)
 	  	  	 if len(@Path)>0 and charindex(' ',@Path)>0
 	  	  	 begin
 	  	  	  	 insert into @paths values (cast(left(@Path,charindex(' ',@Path)-1) as int))
 	  	  	  	 set @Path=substring(@Path,charindex(' ',@Path)+1,8000)
 	  	  	 end
 	  	 end
 	  	 IF len(@Path)>0
 	  	  	 insert into @paths values (@Path)
 	  	 set @Order=replace(replace(replace(replace(replace(@Order,'[','[[]'),'_','[_]'),'%','[%]'),'*','%'),'?','_')
 	  	 select pp.PP_Id,pp.Process_Order,pep.Path_Code 
 	  	 from Production_Plan pp inner join Prdexec_Paths pep on pp.Path_Id=pep.Path_Id
 	  	 where pp.Process_Order like @Order
 	  	 and pp.Path_Id in (select * from @paths)
 	 end
 	 else
 	  	 update Production_Plan set BOM_Formulation_Id=@Formulation where PP_Id=@pp
