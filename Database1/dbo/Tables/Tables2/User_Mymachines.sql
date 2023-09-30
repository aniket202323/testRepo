CREATE TABLE [dbo].[User_Mymachines] (
    [Dept_Id]   INT          NULL,
    [Dept_desc] VARCHAR (50) NULL,
    [Pl_Id]     INT          NULL,
    [Pl_desc]   VARCHAR (50) NULL,
    [Pu_Id]     INT          NULL,
    [Pu_desc]   VARCHAR (50) NULL,
    [ET_Id]     INT          NULL,
    [ET_desc]   VARCHAR (50) NULL,
    [Is_Slave]  BIT          NULL,
    [User_Id]   INT          NULL,
    [Flag]      INT          NULL
);


GO
CREATE CLUSTERED INDEX [icx_user_mymachines]
    ON [dbo].[User_Mymachines]([User_Id] ASC);

