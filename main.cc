#include <iostream>
#include "AsTest.h"
using namespace std;

int main()
{
    int a = 2;
    int b = 0;
    times3(a, b);
    cout<<b<<endl;
    times5(a, b);
    cout<<b<<endl;
    times9(a, b);
    cout<<b<<endl;
    return 0;
}