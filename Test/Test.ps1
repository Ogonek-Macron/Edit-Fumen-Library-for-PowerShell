#Edit-Fumen-Library
#
#正式リリース前の機能
#
#テストランをしているとは限らないので自己責任で

#機能一覧
#
#Concat-Fumen の高速化


using namespace System.Collections.Generic


#複数のテト譜を入力して 1 つのテト譜にまとめる
function Concat-Fumen([List[String]]$Tetfu_Raw_List)
{
    $Tetfu_Raw_List = [List[String]](-split $Tetfu_Raw_List)
    
    $tetfu_table = New-Object List[Object]
    
    switch($Tetfu_Raw_List)
    {
        default
        {
            $tetfu_table.AddRange((EditFumen_RawToTable $_))
        }
    }
    
    $output_tetfu = EditFumen_TableToRaw $tetfu_table
    return $output_tetfu
}
