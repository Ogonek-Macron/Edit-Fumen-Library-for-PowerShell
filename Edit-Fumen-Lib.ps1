#Edit-Fumen-Library for PowerShell
#Ver 0.03 Alpha
#
#ご利用は自己責任で
#
#"Quiz" が含まれるテト譜は未サポート

#本ライブラリのバージョンを取得
function Get-EFL-Version
{
    return 'Ver 0.03 Alpha'
}


#Poll されたデータを解凍
function Base64ToValue([String]$Str, [Int]$StartIndex, [Int]$Length)
{
    $output_value = 0

    for($i = 0; $i -lt $Length; $i++)
    {
        $output_value += [Math]::pow(64, $i) * 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'.IndexOf($Str.Substring($StartIndex + $i, 1))
    }
    return $output_value
}


#データを Poll
function ValueToBase64([Int]$Value, [Int]$Length)
{
    $output_str = ''
    for($i = 0; $i -lt $Length; $i++)
    {
        
        $output_str += 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'.Substring($Value % 64, 1)

        $Value -= $Value % 64
        $Value /= 64

    }
    return $output_str
}


#各ピースの形状の一覧を取得する
function GetPieceShapeTable
{
    #0 South
    #1 West
    #2 North
    #3 East
    $piece_shape_table = @(
        #1 I
        (-01, +00, +01, +02),
        (-10, +00, +10, +20),
        (-01, +00, +01, +02),
        (-10, +00, +10, +20),

        #2 L
        (-01, +00, +01, +09),
        (-10, +00, +10, +11),
        (-09, -01, +00, +01),
        (-11, -10, +00, +10),

        #3 O
        (+00, +01, +10, +11),
        (+00, +01, +10, +11),
        (+00, +01, +10, +11),
        (+00, +01, +10, +11),

        #4 Z
        (-01, +00, +10, +11),
        (-09, +00, +01, +10),
        (-01, +00, +10, +11),
        (-09, +00, +01, +10),

        #5 T
        (-01, +00, +01, +10),
        (-10, +00, +01, +10),
        (-10, -01, +00, +01),
        (-10, -01, +00, +10),

        #6 J
        (-01, +00, +01, +11),
        (-10, -09, +00, +10),
        (-11, -01, +00, +01),
        (-10, +00, +09, +10),

        #7 S
        (+00, +01, +09, +10),
        (-11, -01, +00, +10),
        (+00, +01, +09, +10),
        (-11, -01, +00, +10)
    )
    return ,$piece_shape_table
}


#テーブル形式に展開したフィールド情報をもとに、ミノを設置する
function EditTable_LockPiece([System.Collections.Generic.List[int]]$FieldData, [int]$Piece, [int]$Rotation, [int]$Location)
{
    if($Piece -ne 0)
    {
        #各ピースの形状に関する情報を取得
        $piece_shape_table = GetPieceShapeTable
        
        for($i = 0; $i -lt 4; $i++)
        {
            
            $FieldData[$Location + $piece_shape_table[($Piece - 1) * 4 + $Rotation][$i]] = $Piece
        }

    }
    return ,$FieldData
}


#テーブル形式に展開したフィールド情報をもとに、埋まっている段を消去する
function EditTable_ClearFilledLine([System.Collections.Generic.List[int]]$FieldData)
{
    for($i = 220; $i -ge 0; $i -= 10)
    {
        if($FieldData.IndexOf(0, $i, 10) -eq -1) #0 が無ければその段を消す
        {
            $FieldData.RemoveRange($i, 10)
        }
    }
    #消した分を足す
    $FieldData.InsertRange(0, [int[]]@(0) * (240 - $FieldData.count))
    return ,$FieldData
}


#テーブル形式に展開したフィールド情報をもとに、せり上げる
function EditTable_Raise([System.Collections.Generic.List[int]]$FieldData)
{
    $FieldData.RemoveRange(0, 10)
    $FieldData.AddRange([int[]]@(0) * 10)
    return ,$FieldData
}


#テーブル形式に展開したフィールド情報をもとに、左右を反転させる
function EditTable_Mirror([System.Collections.Generic.List[int]]$FieldData)
{
    for($i = 0; $i -le 220; $i += 10) #お邪魔の段は反転しない
    {
        $FieldData.Reverse($i, 10)
    }
    return ,$FieldData
}


#フィールドの更新
function EditTable_UpdateField([System.Collections.Generic.List[int]]$FieldData, [int]$Piece, [int]$Rotation, [int]$Location, [int]$Flag_Lock, [int]$Flag_Raise, [int]$Flag_Mirror)
{
    if($Flag_Lock -eq 1)
    {
        #置く (未対応)
        $FieldData = EditTable_LockPiece $FieldData $Piece $Rotation $Location

        #消す
        $FieldData = EditTable_ClearFilledLine $FieldData
    
        #せり上げる
        if($Flag_Raise -eq 1)
        {
            $FieldData = EditTable_Raise $FieldData
        }

        #反転
        if($Flag_Mirror -eq 1)
        {
            $FieldData = EditTable_Mirror $FieldData
        }
    }

    return ,$FieldData
}


#URL 形式のデータをテーブルに展開する
function EditFumen_RawToTable([String]$Tetfu)
{
    #コメントの詳細な編集には未対応
    #ミノの設置には未対応
    #Quiz 機能には非対応
    #
    #
    #1 ページ目用初期設定

    $Tetfu = $Tetfu -replace '\?', ''
    $ptr = $Tetfu.IndexOf('@') + 1

    $field_prev = [System.Collections.Generic.List[int]](@(0) * 240)
    $comment_prev_length = 0
    $comment_prev = ''
    $vh_counter = 0

    #全体のテーブル
    $data_list_table = New-Object System.Collections.Generic.List[Object]


    #ここからループ対象
    Do
    {
        $field_diff = New-Object System.Collections.Generic.List[int](240)
        $field_current = New-Object System.Collections.Generic.List[int](240)

        #フィールドの差分を出力
        if($vh_counter -eq 0)　#vh 省略区間外
        {
            do
            {
                $field_value = Base64ToValue $Tetfu $ptr 2
    
                $cell_count = $field_value % 240
                $cell_diff = ($field_value - $cell_count) / 240

                $field_diff.AddRange([int[]]@($cell_diff) * ($cell_count + 1)) 
                $ptr += 2

            } while($field_diff.count -lt 240)

            #vh 先頭処理
            if($field_value -eq 2159)
            {
                $vh_counter = Base64ToValue $Tetfu $ptr 1
                $ptr += 1
            }
        }
        else #vh 省略区間内
        {
            $field_diff = [System.Collections.Generic.List[int]](@(8) * 240)
            $vh_counter--
        }


        #現在のフィールドを計算
        for($i = 0; $i -le 239; $i++)
        {
            $field_current.Add($field_diff[$i] + $field_prev[$i] - 8) | Out-Null
        }


        #ミノ、フラグの解凍

        $flags_value = Base64ToValue $Tetfu $ptr 3
        $ptr += 3

        #操作中のミノの種類
        $piece = $flags_value % 8
        $flags_value = [Math]::Floor($flags_value / 8)

        #操作中のミノの向き
        $rotation = $flags_value % 4
        $flags_value = [Math]::Floor($flags_value / 4)

        #操作中のミノの場所
        $location = $flags_value % 240
        $flags_value = [Math]::Floor($flags_value / 240)

        #ミノ非選択時
        if($piece -eq 0)
        {
            $rotation = 0
            $location = 0
        }

        #せりあがりフラグ
        $flag_raise = $flags_value % 2
        $flags_value = [Math]::Floor($flags_value / 2)

        #鏡フラグ
        $flag_mirror = $flags_value % 2
        $flags_value = [Math]::Floor($flags_value / 2)

        #色フラグ
        if($data_list_table.Count -eq 0)
        {
            $flag_color = $flags_value % 2
        }
        $flags_value = [Math]::Floor($flags_value / 2)

        #コメントフラグ
        $flag_comment = $flags_value % 2
        $flags_value = [Math]::Floor($flags_value / 2)

        #接着フラグ
        $flag_lock = ($flags_value + 1) % 2


        #コメントの文字数
        switch($flag_comment)
        {
            1
            {
                $comment_current_length = Base64ToValue $Tetfu $ptr 2
                $ptr += 2
            }
            0
            {
                $comment_current_length = $comment_prev_length
            }
        }

        #コメント文字列解凍
        switch($flag_comment)
        {
            1
            {
                #仮コード (未サポート機能)
                $comment_current = $Tetfu.Substring($ptr, (5 * [Math]::Ceiling($comment_current_length / 4)))
                #コメントの分ポインタを動かす
                $ptr += (5 * [Math]::Ceiling($comment_current_length / 4))
            }
            0
            {
                $comment_current = $comment_prev
            }
        }


        #後処理

        #フィールドの更新
        $field_prev = New-Object System.Collections.Generic.List[int]([System.Collections.Generic.List[int[]]]$field_current)
        $field_prev = EditTable_UpdateField $field_prev $piece $rotation $location $flag_lock $flag_raise $flag_mirror



        #Quiz の更新
        #$comment_prev_length
        #$comment_prev
        #
        #仮コード (未サポート機能)
        $comment_prev_length = $comment_current_length
        $comment_prev = $comment_current
        #仮コードここまで

        $data_list_table.Add([object]@{field_current = $field_current; field_updated = $field_prev; piece = $piece; rotation = $rotation; location = $location; flag_raise = $flag_raise; flag_mirror = $flag_mirror; flag_color = $flag_color; flag_comment = $flag_comment; flag_lock = $flag_lock; comment_current_length = $comment_current_length; comment_current = $comment_current; comment_updated_length = $comment_prev_length; comment_updated = $comment_prev;}) | Out-Null


    } while($ptr -lt $Tetfu.Length)
    #echo $data_list_table.GetType()
    

    return ,$data_list_table
}


#テーブル形式のデータをエンコードする
function EditFumen_TableToRaw([System.Collections.Generic.List[object]]$Data_List_Table)
{
    #コメントの詳細な編集には未対応
    #vh 関連は仮対応
    #
    #1 ページ目用初期設定

    $field_prev = [System.Collections.Generic.List[int]](@(0) * 240)
    $comment_prev_length = 0
    $comment_prev = ''
    #$vh_counter = 0

    #全体のテーブル
    $encoder_table = New-Object System.Collections.Generic.List[System.Text.StringBuilder]

    #ここからループ対象

    for($page = 0; $page -lt $Data_List_Table.Count; $page++)
    {
        #echo $page.GetType()
        
        $field_diff = New-Object System.Collections.Generic.List[int](240)
        
        $field_current = New-Object System.Collections.Generic.List[int]([System.Collections.Generic.List[int[]]]($Data_List_Table[$page].field_current))

        $field_value_list = New-Object System.Collections.Generic.List[int]
        $cell_diff_prev = -1

        #フィールドの差分を計算
        for($i = 0; $i -le 239; $i++)
        {
            $field_diff.Add($field_current[$i] - $field_prev[$i] + 8) | Out-Null
    
            $cell_diff_current = $field_diff[$i]
            if($cell_diff_current -eq $cell_diff_prev)
            {
                $field_value_list[$field_value_list.Count - 1] ++
            }
            else
            {
                $field_value_list.Add($cell_diff_current * 240) | Out-Null
                $cell_diff_prev = $cell_diff_current
            }
        }


        $piece = $Data_List_Table[$page].piece
        $rotation = $Data_List_Table[$page].rotation
        $location = $Data_List_Table[$page].location
        $flag_raise = $Data_List_Table[$page].flag_raise
        $flag_mirror = $Data_List_Table[$page].flag_mirror

        #color
        if($page -eq 0)
        {
            $flag_color = $Data_List_Table[$page].flag_color
        }
        else
        {
            $flag_color = 0
        }

        #lock
        $flag_lock = $Data_List_Table[$page].flag_lock

        #comment
        if($comment_prev.Equals($Data_List_Table[$page].comment_current))
        {
            $flag_comment = 0
            $comment_current_length = 0
            $comment_current = ''
        }
        else
        {
            $flag_comment = 1
            $comment_current_length = $Data_List_Table[$page].comment_current_length
            $comment_current = $Data_List_Table[$page].comment_current
        }

        #Encode
        $building_str = New-Object System.Text.StringBuilder
        #フィールド部分 (後で vh の対応をする)
        $building_str.Append(($field_value_list | ForEach-Object {ValueToBase64 $PSItem 2}) -join '') | Out-Null
        #vh 仮対応コード
        if($field_value_list.Count -eq 1)
        {
            $building_str.Append('A') | Out-Null
        }
        #ミノ・フラグ
        $building_str.Append((ValueToBase64 ($piece + $rotation * 8 + $location * 32 + $flag_raise * 7680 + $flag_mirror * 15360 + $flag_color * 30720 + $flag_comment * 61440 + (($flag_lock + 1) % 2) * 122880) 3)) | Out-Null
        #コメント
        if($flag_comment -eq 1)
        {
            $building_str.Append((ValueToBase64 $comment_current_length 2)) | Out-Null
            $building_str.Append($comment_current) | Out-Null
        }
        $encoder_table.Add($building_str) | Out-Null

        
        #後処理
        $field_prev = New-Object System.Collections.Generic.List[int]([System.Collections.Generic.List[int[]]]($Data_List_Table[$page].field_updated))
        $comment_prev_length = $Data_List_Table[$page].comment_updated_length
        $comment_prev = $Data_List_Table[$page].comment_updated
    }

    $encoder_table = $encoder_table | ForEach-Object {$PSItem.ToString()}

    $raw_str = 'v115@'
    $raw_str += $encoder_table -join ''
    

    for($i = 0; (48 * $i + 47) -le ($raw_str.Length); $i++)
    {
        $raw_str = $raw_str.Insert(48 * $i + 47,'?')
    }
    
    return $raw_str
}

#--------------------------------------------------
# 正式機能？
#--------------------------------------------------

#空のテト譜 Raw データを取得
function Blank-Fumen
{
    return 'v115@vhAAgH'
}


#Raw データからページ数を求める
function Count([String]$Tetfu_Raw)
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    return $tetfu_table.Count
}


#色フラグを取得する
function Get-Color-Flag([String]$Tetfu_Raw)
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    return $tetfu_table[0].flag_color
}


#指定したページを抜き出す (リストで指定可能)
function Get-Pages([String]$Tetfu_Raw, [System.Collections.Generic.List[int]]$PageNo = [System.Collections.Generic.List[int]]::new([int[]](1..(Count $Tetfu_Raw))))
{
    for($i = 0; $i -lt $PageNo.Count; $i++) 
    {
        $PageNo[$i]--
    }

    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    $raw_str = EditFumen_TableToRaw $tetfu_table[$PageNo]
    return $raw_str
}


#テト譜を指定したページ数ずつに分割する
function Chunk([String]$Tetfu_Raw, [int]$Size = 1)
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    
    for($i = 0; $i -lt [math]::Ceiling($tetfu_table.Count / $Size); $i++) 
    {
        EditFumen_TableToRaw $tetfu_table[(($Size * $i)..($Size * ($i + 1) - 1))]
    }
    return
}


#2 つのテト譜を結合する 
function Append-Fumen([String]$Tetfu1_Raw, [String]$Tetfu2_Raw)
{
    $tetfu1_table = EditFumen_RawToTable $Tetfu1_Raw
    $tetfu2_table = EditFumen_RawToTable $Tetfu2_Raw
    $tetfu1_table.AddRange($tetfu2_table)
    $output_tetfu = EditFumen_TableToRaw $tetfu1_table
    return $output_tetfu
}


#テト譜の配列を入力して 1 つのテト譜にまとめる
function Concat-Fumen([System.Collections.Generic.List[String]]$Tetfu_Raw_List)
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw_List[0]
    
    for($i = 1; $i -lt $Tetfu_Raw_List.Count; $i++)
    {
        $tetfu_table_to_append = EditFumen_RawToTable $Tetfu_Raw_List[$i]
        $tetfu_table.AddRange($tetfu_table_to_append)
    }
    
    $output_tetfu = EditFumen_TableToRaw $tetfu_table
    return $output_tetfu
}


#テト譜の配列を入力して区切り用テト譜を挟みながら 1 つのテト譜にまとめる
function Join-Fumen([System.Collections.Generic.List[String]]$Tetfu_Raw_List, [String]$Tetfu_Raw_Delimiter = (Blank-Fumen))
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw_List[0]

    for($i = 1; $i -lt $Tetfu_Raw_List.Count; $i++)
    {
        $tetfu_table_delimiter = EditFumen_RawToTable $Tetfu_Raw_Delimiter
        $tetfu_table.AddRange($tetfu_table_delimiter)

        $tetfu_table_to_append = EditFumen_RawToTable $Tetfu_Raw_List[$i]
        $tetfu_table.AddRange($tetfu_table_to_append)
    }
    
    $output_tetfu = EditFumen_TableToRaw $tetfu_table
    return $output_tetfu
}


#テト譜の挿入
function Insert-Fumen([String]$Tetfu1_Raw, [int]$1_Based_Index, [String]$Tetfu2_Raw)
{
    $tetfu1_table = EditFumen_RawToTable $Tetfu1_Raw
    $tetfu2_table = EditFumen_RawToTable $Tetfu2_Raw
    $tetfu1_table.InsertRange($1_Based_Index - 1, $tetfu2_table)
    $output_tetfu = EditFumen_TableToRaw $tetfu1_table
    return $output_tetfu
}


#指定した 1 ページを削除する
function Remove-At([String]$Tetfu_Raw, [int]$1_Based_Index)
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    $tetfu_table.RemoveAt($1_Based_Index - 1)
    $output_tetfu = EditFumen_TableToRaw $tetfu_table
    return $output_tetfu
}


#指定したページ範囲を削除する
function Remove-Range([String]$Tetfu_Raw, [int]$1_Based_Index, [int]$Count)
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    $tetfu_table.RemoveRange($1_Based_Index - 1, $Count)
    $output_tetfu = EditFumen_TableToRaw $tetfu_table
    return $output_tetfu
}


#指定したページの接着フラグを取得する (リストで指定可能)
function Get-Raise-Flag([String]$Tetfu_Raw, [System.Collections.Generic.List[int]]$PageNo = [System.Collections.Generic.List[int]]::new([int[]](1..(Count $Tetfu_Raw))))
{
    for($i = 0; $i -lt $PageNo.Count; $i++) 
    {
        $PageNo[$i]--
    }

    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    return ,$tetfu_table[$PageNo].flag_lock
}


#指定したページのせりあがりフラグを取得する (リストで指定可能)
function Get-Raise-Flag([String]$Tetfu_Raw, [System.Collections.Generic.List[int]]$PageNo = [System.Collections.Generic.List[int]]::new([int[]](1..(Count $Tetfu_Raw))))
{
    for($i = 0; $i -lt $PageNo.Count; $i++) 
    {
        $PageNo[$i]--
    }

    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    return ,$tetfu_table[$PageNo].flag_raise
}


#指定したページの鏡フラグを取得する (リストで指定可能)
function Get-Mirror-Flag([String]$Tetfu_Raw, [System.Collections.Generic.List[int]]$PageNo = [System.Collections.Generic.List[int]]::new([int[]](1..(Count $Tetfu_Raw))))
{
    for($i = 0; $i -lt $PageNo.Count; $i++) 
    {
        $PageNo[$i]--
    }

    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    return ,$tetfu_table[$PageNo].flag_mirror
}


#指定したページの地形の高さを取得する (リストで指定可能)
function Get-Height([String]$Tetfu_Raw, [System.Collections.Generic.List[int]]$PageNo = [System.Collections.Generic.List[int]]::new([int[]](1..(Count $Tetfu_Raw))))
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw

    for($i = 0; $i -lt $PageNo.Count; $i++) 
    {
        (23 - [math]::Floor($tetfu_table[$PageNo[$i] - 1].field_current.FindIndex({$args -ne 0}) / 10)) % 24
    }  

   return
}


#指定したページをフラグに基づいて処理した後に残る地形の高さを取得する (リストで指定可能)
function Get-Height-Updated([String]$Tetfu_Raw, [System.Collections.Generic.List[int]]$PageNo = [System.Collections.Generic.List[int]]::new([int[]](1..(Count $Tetfu_Raw))))
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw

    for($i = 0; $i -lt $PageNo.Count; $i++) 
    {
        (23 - [math]::Floor($tetfu_table[$PageNo[$i] - 1].field_updated.FindIndex({$args -ne 0}) / 10)) % 24
    }  

   return
}

#指定したページに置かれているブロック数を取得する (リストで指定可能)
function Count-Blocks([String]$Tetfu_Raw, [System.Collections.Generic.List[int]]$PageNo = [System.Collections.Generic.List[int]]::new([int[]](1..(Count $Tetfu_Raw))))
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    for($i = 0; $i -lt $PageNo.Count; $i++) 
    {
        [Linq.Enumerable]::Count($tetfu_table[$PageNo[$i] - 1].field_current[0..229] , [Func[object,bool]]{ param($x) [int]($x -ne 0) * 8 })
    }
    return
}


#指定したページをフラグに基づいて処理した後に置かれているブロック数を取得する (リストで指定可能)
function Count-Blocks-In-Updated([String]$Tetfu_Raw, [System.Collections.Generic.List[int]]$PageNo = [System.Collections.Generic.List[int]]::new([int[]](1..(Count $Tetfu_Raw))))
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    for($i = 0; $i -lt $PageNo.Count; $i++) 
    {
        [Linq.Enumerable]::Count($tetfu_table[$PageNo[$i] - 1].field_updated[0..229] , [Func[object,bool]]{ param($x) [int]($x -ne 0) * 8 })
    }
    return
}


#指定したページに置かれているブロック数をすべて灰色にする (リストで指定可能)
function Set-To-Gray([String]$Tetfu_Raw, [System.Collections.Generic.List[int]]$PageNo = [System.Collections.Generic.List[int]]::new([int[]](1..(Count $Tetfu_Raw))))
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    
    for($i = 0; $i -lt $PageNo.Count; $i++) 
    {
        #置かれているブロック数を灰色に
        for($j = 0; $j -lt 240; $j++)
        {
            $tetfu_table[$PageNo[$i] - 1].field_current[$j] = [int](($tetfu_table[$PageNo[$i] - 1].field_current[$j]) -ne 0) * 8
        }

        #フィールドの更新
        $field_data = New-Object System.Collections.Generic.List[int]([System.Collections.Generic.List[int[]]]$tetfu_table[$PageNo[$i] - 1].field_current)
        $field_data = EditTable_UpdateField $field_data $tetfu_table[$PageNo[$i] - 1].piece $tetfu_table[$PageNo[$i] - 1].rotation $tetfu_table[$PageNo[$i] - 1].location $tetfu_table[$PageNo[$i] - 1].flag_lock $tetfu_table[$PageNo[$i] - 1].flag_raise $tetfu_table[$PageNo[$i] - 1].flag_mirror

        $tetfu_table[$PageNo[$i] - 1].field_updated = $field_data
    }

    $raw_str = EditFumen_TableToRaw $tetfu_table
    return $raw_str
}


#指定したページの埋まっている段を接着フラグにかかわらず消去する (リストで指定可能)
function Clear-Filled-Line([String]$Tetfu_Raw, [System.Collections.Generic.List[int]]$PageNo = [System.Collections.Generic.List[int]]::new([int[]](1..(Count $Tetfu_Raw))))
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    
    for($i = 0; $i -lt $PageNo.Count; $i++) 
    {
        #ライン消去
        $tetfu_table[$PageNo[$i] - 1].field_current = EditTable_ClearFilledLine $tetfu_table[$PageNo[$i] - 1].field_current
        
        #フィールドの更新
        $field_data = New-Object System.Collections.Generic.List[int]([System.Collections.Generic.List[int[]]]$tetfu_table[$PageNo[$i] - 1].field_current)
        $field_data = EditTable_UpdateField $field_data $tetfu_table[$PageNo[$i] - 1].piece $tetfu_table[$PageNo[$i] - 1].rotation $tetfu_table[$PageNo[$i] - 1].location $tetfu_table[$PageNo[$i] - 1].flag_lock $tetfu_table[$PageNo[$i] - 1].flag_raise $tetfu_table[$PageNo[$i] - 1].flag_mirror
        
        $tetfu_table[$PageNo[$i] - 1].field_updated = $field_data
    }

    $raw_str = EditFumen_TableToRaw $tetfu_table
    return $raw_str
}


#指定したページのミノを接着フラグにかかわらず設置する (リストで指定可能)
function Lock-Piece([String]$Tetfu_Raw, [System.Collections.Generic.List[int]]$PageNo = [System.Collections.Generic.List[int]]::new([int[]](1..(Count $Tetfu_Raw))))
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    
    for($i = 0; $i -lt $PageNo.Count; $i++) 
    {
        #ミノ設置
        $tetfu_table[$PageNo[$i] - 1].field_current = EditTable_LockPiece $tetfu_table[$PageNo[$i] - 1].field_current $tetfu_table[$PageNo[$i] - 1].piece $tetfu_table[$PageNo[$i] - 1].rotation $tetfu_table[$PageNo[$i] - 1].location
        
        $tetfu_table[$PageNo[$i] - 1].piece = 0
        $tetfu_table[$PageNo[$i] - 1].rotation = 0
        $tetfu_table[$PageNo[$i] - 1].location = 0

        #フィールドの更新
        $field_data = New-Object System.Collections.Generic.List[int]([System.Collections.Generic.List[int[]]]$tetfu_table[$PageNo[$i] - 1].field_current)
        $field_data = EditTable_UpdateField $field_data $tetfu_table[$PageNo[$i] - 1].piece $tetfu_table[$PageNo[$i] - 1].rotation $tetfu_table[$PageNo[$i] - 1].location $tetfu_table[$PageNo[$i] - 1].flag_lock $tetfu_table[$PageNo[$i] - 1].flag_raise $tetfu_table[$PageNo[$i] - 1].flag_mirror
        
        $tetfu_table[$PageNo[$i] - 1].field_updated = $field_data
    }

    $raw_str = EditFumen_TableToRaw $tetfu_table
    return $raw_str
}


#指定したページのフィールドをフラグにかかわらずせり上げる (リストで指定可能)
function Raise-Field([String]$Tetfu_Raw, [System.Collections.Generic.List[int]]$PageNo = [System.Collections.Generic.List[int]]::new([int[]](1..(Count $Tetfu_Raw))))
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    
    for($i = 0; $i -lt $PageNo.Count; $i++) 
    {
        #ミノ設置
        $tetfu_table[$PageNo[$i] - 1].field_current = EditTable_Raise $tetfu_table[$PageNo[$i] - 1].field_current

        $tetfu_table[$PageNo[$i] - 1].flag_raise = 0
        
        #フィールドの更新
        $field_data = New-Object System.Collections.Generic.List[int]([System.Collections.Generic.List[int[]]]$tetfu_table[$PageNo[$i] - 1].field_current)
        $field_data = EditTable_UpdateField $field_data $tetfu_table[$PageNo[$i] - 1].piece $tetfu_table[$PageNo[$i] - 1].rotation $tetfu_table[$PageNo[$i] - 1].location $tetfu_table[$PageNo[$i] - 1].flag_lock $tetfu_table[$PageNo[$i] - 1].flag_raise $tetfu_table[$PageNo[$i] - 1].flag_mirror
        
        $tetfu_table[$PageNo[$i] - 1].field_updated = $field_data
    }

    $raw_str = EditFumen_TableToRaw $tetfu_table
    return $raw_str
}


#指定したページのフィールドをフラグにかかわらず左右反転する (リストで指定可能)
function Mirror-Field([String]$Tetfu_Raw, [System.Collections.Generic.List[int]]$PageNo = [System.Collections.Generic.List[int]]::new([int[]](1..(Count $Tetfu_Raw))))
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    
    for($i = 0; $i -lt $PageNo.Count; $i++) 
    {
        #ミノ設置
        $tetfu_table[$PageNo[$i] - 1].field_current = EditTable_Mirror $tetfu_table[$PageNo[$i] - 1].field_current

        $tetfu_table[$PageNo[$i] - 1].flag_mirror = 0
        
        #フィールドの更新
        $field_data = New-Object System.Collections.Generic.List[int]([System.Collections.Generic.List[int[]]]$tetfu_table[$PageNo[$i] - 1].field_current)
        $field_data = EditTable_UpdateField $field_data $tetfu_table[$PageNo[$i] - 1].piece $tetfu_table[$PageNo[$i] - 1].rotation $tetfu_table[$PageNo[$i] - 1].location $tetfu_table[$PageNo[$i] - 1].flag_lock $tetfu_table[$PageNo[$i] - 1].flag_raise $tetfu_table[$PageNo[$i] - 1].flag_mirror
        
        $tetfu_table[$PageNo[$i] - 1].field_updated = $field_data
    }

    $raw_str = EditFumen_TableToRaw $tetfu_table
    return $raw_str
}


#指定したページをフラグに基づいて操作した後の地形に置き換える
function Update-Field([String]$Tetfu_Raw, [System.Collections.Generic.List[int]]$PageNo = [System.Collections.Generic.List[int]]::new([int[]](1..(Count $Tetfu_Raw))))
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    
    for($i = 0; $i -lt $PageNo.Count; $i++) 
    {
        #フィールドの更新
        $field_data = New-Object System.Collections.Generic.List[int]([System.Collections.Generic.List[int[]]]$tetfu_table[$PageNo[$i] - 1].field_current)
        $field_data = EditTable_UpdateField $field_data $tetfu_table[$PageNo[$i] - 1].piece $tetfu_table[$PageNo[$i] - 1].rotation $tetfu_table[$PageNo[$i] - 1].location $tetfu_table[$PageNo[$i] - 1].flag_lock $tetfu_table[$PageNo[$i] - 1].flag_raise $tetfu_table[$PageNo[$i] - 1].flag_mirror
        
        $tetfu_table[$PageNo[$i] - 1].field_current = $field_data
        $tetfu_table[$PageNo[$i] - 1].field_updated = $field_data
        
        $tetfu_table[$PageNo[$i] - 1].piece = 0
        $tetfu_table[$PageNo[$i] - 1].rotation = 0
        $tetfu_table[$PageNo[$i] - 1].location = 0
        $tetfu_table[$PageNo[$i] - 1].flag_raise = 0
        $tetfu_table[$PageNo[$i] - 1].flag_mirror = 0
    }

    $raw_str = EditFumen_TableToRaw $tetfu_table
    return $raw_str
}


#指定したページに置かれているブロックをすべて消去する (リストで指定可能)
function Clear-Field([String]$Tetfu_Raw, [System.Collections.Generic.List[int]]$PageNo = [System.Collections.Generic.List[int]]::new([int[]](1..(Count $Tetfu_Raw))))
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    
    for($i = 0; $i -lt $PageNo.Count; $i++) 
    {
        #ブロック消去
        $tetfu_table[$PageNo[$i] - 1].field_current = [System.Collections.Generic.List[int]](@(0) * 240)
        
        #フィールドの更新
        $field_data = New-Object System.Collections.Generic.List[int]([System.Collections.Generic.List[int[]]]$tetfu_table[$PageNo[$i] - 1].field_current)
        $field_data = EditTable_UpdateField $field_data $tetfu_table[$PageNo[$i] - 1].piece $tetfu_table[$PageNo[$i] - 1].rotation $tetfu_table[$PageNo[$i] - 1].location $tetfu_table[$PageNo[$i] - 1].flag_lock $tetfu_table[$PageNo[$i] - 1].flag_raise $tetfu_table[$PageNo[$i] - 1].flag_mirror
        
        $tetfu_table[$PageNo[$i] - 1].field_updated = $field_data
    }

    $raw_str = EditFumen_TableToRaw $tetfu_table
    return $raw_str
}


#指定したページのコメントを除去する (リストで指定可能)
#コメントの詳細編集対応時にルーチン変更予定
function Clear-Comment([String]$Tetfu_Raw, [System.Collections.Generic.List[int]]$PageNo = [System.Collections.Generic.List[int]]::new([int[]](1..(Count $Tetfu_Raw))))
{
    $tetfu_table = EditFumen_RawToTable $Tetfu_Raw
    
    for($i = 0; $i -lt $PageNo.Count; $i++) 
    {
        $tetfu_table[$PageNo[$i] - 1].comment_current_length = 0
        $tetfu_table[$PageNo[$i] - 1].comment_current = ''
        $tetfu_table[$PageNo[$i] - 1].comment_updated_length = 0
        $tetfu_table[$PageNo[$i] - 1].comment_updated = ''
    }
    
    $raw_str = EditFumen_TableToRaw $tetfu_table
    return $raw_str
}
