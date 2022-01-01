using System;
using System.Collections.Generic;

namespace lihancode
{
    class Program
    {
        static bool CheckStringIsNum(string num)
        {
            foreach(char c in num.ToCharArray()) 
            {
                if (c > '9' || c < '0') 
                {
                    Console.WriteLine("This is not a valid number:" + num);
                    return false;
                }
            }    
            return true;
        }

        static char[] ReverseString(string num)
        {
            char[] arrStr = num.ToCharArray();
            int len = arrStr.Length;
            for(int i = 0; i < len / 2; i++)
            {
                char c = arrStr[i];
                arrStr[i] = arrStr[len - i - 1];
                arrStr[len - i - 1] = c;
            }
            return arrStr;
        }

        static string AddTwoStrings(string s1, string s2)
        {
            //"18" + "90" = "108"
            char[] rs1 = ReverseString(s1);
            char[] rs2 = ReverseString(s2);
            int maxLen = (rs1.Length > rs2.Length) ? (rs1.Length) : (rs2.Length);

            List<char> resultCharList = new List<char>();
            
            int carry = 0;
            for (int i = 0; i < maxLen; i++)
            {
                int i1 = 0;
                int i2 = 0;
                if (rs1.Length >= i + 1) {
                    i1 = rs1[i] - '0';
                }
                if (rs2.Length >= i + 1) {
                    i2 = rs2[i] - '0';
                }
                int result = i1 + i2 + carry;
                int ones =  result % 10;
                carry = result / 10;
                resultCharList.Add((char)(ones + 48));
            }
            if (carry != 0)
            {
                resultCharList.Add((char)(carry + 48));
            }
            string retResult = new string(resultCharList.ToArray());
            string retReversedResult = new string(ReverseString(retResult));
            return retReversedResult;
        }

        static void Main(string[] args)
        {
            Console.WriteLine("Please input the first number:");
            string numb1 = Console.ReadLine();
            Console.WriteLine("Please input the second number:");
            string numb2 = Console.ReadLine();

            bool isNum;
            isNum = CheckStringIsNum(numb1);
            if (isNum == false) {return;}

            isNum = CheckStringIsNum(numb2);
            if (isNum == false) {return;}

            Console.WriteLine("All numbers are checked and now we continue.");
            char[] numArr1 = ReverseString(numb1);
            char[] numArr2 = ReverseString(numb2);
            string finalResult = "";
            int pos2 = 0;
            foreach(char c2 in numArr2)
            {
                int pos1 = 0;
                foreach(char c1 in numArr1)
                {
                    int p = (c2 - '0') * (c1 - '0');

                    string pStr = p.ToString();
                    for (int i = 0; i < pos2 + pos1; i++)
                    {
                        pStr = pStr + "0";
                    }
                    finalResult = AddTwoStrings(finalResult, pStr);

                    pos1++;
                }

                pos2++;
            }

            Console.WriteLine("Final result is: " + finalResult);
        }
    }
}
