CREATE TABLE [dbo].[In_Process_Bins] (
    [Bin_Id]             INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Actual_Dimension_A] REAL         NULL,
    [Actual_Dimension_X] REAL         NULL,
    [Actual_Dimension_Y] REAL         NULL,
    [Actual_Dimention_Z] REAL         NULL,
    [Bin_Code]           VARCHAR (50) NOT NULL,
    [Comment_Id]         INT          NULL,
    [Current_PU_Id]      INT          NULL,
    [Home_PU_Id]         INT          NULL,
    [Is_Active]          BIT          NOT NULL,
    [Orientation_X]      TINYINT      NULL,
    [Orientation_Y]      TINYINT      NULL,
    [Orientation_Z]      TINYINT      NULL,
    [ProdStatus_Id]      INT          NULL,
    [Std_Dimension_X]    REAL         NULL,
    [Std_Dimension_Y]    REAL         NULL,
    [Std_Dimension_Z]    REAL         NULL,
    CONSTRAINT [InProcessBins_PK_BinId] PRIMARY KEY CLUSTERED ([Bin_Id] ASC),
    CONSTRAINT [InProcessBins_FK_ProdStatusId] FOREIGN KEY ([ProdStatus_Id]) REFERENCES [dbo].[Production_Status] ([ProdStatus_Id])
);

