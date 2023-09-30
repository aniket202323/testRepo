CREATE TABLE [dbo].[Array_Data] (
    [Array_Id]     INT     IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Data]         IMAGE   NULL,
    [Element_Size] INT     NULL,
    [Num_Elements] INT     NULL,
    [PctGood]      IMAGE   NULL,
    [ShouldDelete] TINYINT NULL,
    CONSTRAINT [Array_Data_PK_ArrayId] PRIMARY KEY CLUSTERED ([Array_Id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ArrayData_IX_ShouldDelete]
    ON [dbo].[Array_Data]([ShouldDelete] ASC);

