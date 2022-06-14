#Concat-Fumen 関数の速度テストルーチン
#
#先に Edit-Fumen-Lib.ps1 を実行しておくこと

using namespace System.Collections.Generic


#テスト用に結合前のテト譜のリストを作成

#取りあえず以下の 3 つのテト譜を順番に回してみる
#
#https://tinyurl.com/2ad64bku
#https://tinyurl.com/27hrbpcr
#https://tinyurl.com/275a78ru

#Concat-Fumen のテストをしたいので、一旦 1 ページずつのテト譜にバラす

$List_A = [List[String]](Chunk v115@1gAtGewhBtGewhAtCehlh0AtwhRpAeR4glg0BtwhRp?R4Aeglg0AtKeAgW+AQFn2AwXHDBQZtwClOP6AupeRA1d0AC?CYPNBXYcRA1Qn6ARrDfETYp6Alvs2AiJEfET4d3Blvs2AGd?AAA1gAPAeAtFeBPBtFeQaQpAtAehWFeQ4AewDEewSAtAeQL?glNeAAP+AQFn2AwXHDBQZtwCluCLBORsRA1d0ACCYPNBXYc?RA1Qn6ARrDfETYp6Alvs2AiJEfET4d3Blvs2AGdAAA2gQpQ?aEeQaBeRag0DewhxSAeAth0AewhAPwhxSwDwSAtglgWRpwh?glwDgHSagWAeQ4JeAAP+AQFn2AwXHDBQZtwClewRBOuwRA1?d0ACCYPNBXYcRA1Qn6ARrDfETYp6Alvs2AiJEfET4d3Blvs?2AGdAAA2gxSBeQ4AewhCexSgHAeR4whAehlRaiHAewhAeBt?QpQaglAPAewSgHhWAtQpQaxwglAewSJeAAPABQFRVBuJjRA?1d0ACie0wCyCIOB4XHDBQZFSAVS02AwX3JBDq2KBlvs2AEq?DfET4cBClvs2AGFEfET4dBB)
$List_B = [List[String]](Chunk v115@1gAtGewhBtGewhAtCehlh0AtwhRpAeR4glg0BtwhRp?R4Aeglg0AtKeAgW+AQFn2AwXHDBQZtwClOP6AupeRA1d0AC?CYPNBXYcRA1Qn6ARrDfETYp6Alvs2AiJEfET4d3Blvs2AGd?AAA1gAPAeAtFeBPBtFeQaQpAtAehWFeQ4AewDEewSAtAeQL?glNeAAP+AQFn2AwXHDBQZtwCluCLBORsRA1d0ACCYPNBXYc?RA1Qn6ARrDfETYp6Alvs2AiJEfET4d3Blvs2AGdAAA3gAPR?4CeQaBeAPQpQ4glCeQawhAeQailhHglQpwhAeAPwSAtgWgH?APglQpwhhHQahlgHglg0JeAAP+AQFn2AwXHDBQZtwClewRB?OuwRA1d0ACCYPNBXYcRA1Qn6ARrDfETYp6Alvs2AiJEfET4?d3Blvs2AGdAAA4gxDQ4AewhDexDgWR4whglgWQaAewhhWAe?Q4QLgWAewhAeQaglAeBtQLAPQaRpQahlg0hWJeAAPABQFRV?BuJjRA1d0ACie0wCyCIOB4XHDBQZFSAVS02AwX3JBDq2KBl?vs2AEqDfET4cBClvs2AGFEfET4dBB)
$List_C = [List[String]](Chunk v115@1gAtGewhBtGewhAtCehlh0AtwhRpAeR4glg0BtwhRp?R4Aeglg0AtKeAgW+AQFn2AwXHDBQZtwClOP6AupeRA1d0AC?CYPNBXYcRA1Qn6ARrDfETYp6Alvs2AiJEfET4d3Blvs2AGd?AAA1gAPAeAtFeBPBtFeQaQpAtAehWFeQ4AewDEewSAtAeQL?glNeAAP+AQFn2AwXHDBQZtwCluCLBORsRA1d0ACCYPNBXYc?RA1Qn6ARrDfETYp6Alvs2AiJEfET4d3Blvs2AGdAAA0gg0B?eAPEeQag0AeBPBtCewwQpAtAPBeAtgWwSQaQpwhAtAewDgl?AeAPSaAtwSAegWAeQaQLwSwhJeAAPABQFRVBuJjRA1d0ACi?e0wCV+XHByXHDBQZFSAVS02AwX3JBDqW9Alvs2AEqDfET4c?BClvs2AGFEfET4dBB0ggHEeQ4AewhAegHCeBPR4whBPQLRp?AeBPAthWAewSAPQpAtgWglwhgWAeAPAewSAeAtxwRpJeAAP?ABQFRVBuJjRA1d0ACie0wCyCIOB4XHDBQZFSAVS02AwX3JB?Dq2KBlvs2AEqDfET4cBClvs2AGFEfET4dBB)


#3 種類を順番に回すためのリストを作る
#10000 を掛けることで 30000 回分のデータにしている

$List_D = [List[List[String]]](($List_A, $List_B, $List_C) * 10000)


#計測開始
Measure-Command{
    #結合結果を $List_E に格納する
    $List_E = New-Objet List[String]($List_D.Count)
    
    #30000 回ループさせる
    Switch($List_D)
    {
        default
        {
            #4 つのテト譜を 1 つに結合し、結果を格納する
            $List_E.Add((Concat-Fumen $_))
        }
    }
}

#計測終了

#筆者の環境で 18 分 56 秒かかった (PowerShell 7.2.4)
