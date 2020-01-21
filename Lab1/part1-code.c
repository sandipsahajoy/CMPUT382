#include <stdio.h>
#include <stdlib.h>

//incorrect declaration of int value
void test1()
{
    int *a, x = 3;
    a = &x;
    *a = *a + 2;
    printf("%d",*a);
}

//incorrect pointer declaration(b)
void test2()
{
    int *a, *b;
    a = (int*) malloc(sizeof(int));
    b = (int*) malloc(sizeof(int));
    if (!(a && b))
    {
        printf("Out of memory");
        exit(-1);
    }
    *a = 2;
    *b = 3;
    printf("%d\n%d",*a,*b);
}

//incorrect allocation of memory for 1000 int
void test3()
{
    int i, *a = (int*) malloc(1000*sizeof(int));
    if (!a)
    {
        printf("Out of memory");
        exit(-1);
    }
    for (i = 0; i < 1000; i++)
    {
        *(i+a)=i;
        printf("%d\n",*(i+a));
    }
}

//incorrect dynamically allocated a 2D array
void test4()
{
    int **a = (int**) malloc(3 * sizeof(int*));
    for (int i=0; i<3; i++)
    {
        a[i] = (int*)malloc(100 * sizeof(int));
    }
    a[1][1] = 5;
    printf("%d",a[1][1]);
}

//incorrect if statement
void test5()
{
    int *a = (int*) malloc(sizeof(int));
    scanf("%d",a);
    if (!*a)
    {
        printf("Value is 0\n");
    }
}

void main()
{
    //test1();
    //test2();
    //test3();
    //test4();
    //test5();
}
